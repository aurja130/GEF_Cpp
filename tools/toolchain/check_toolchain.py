# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Aurora Jahan
# See LICENSE.txt in the repository root for the full license text.
"""Check the pinned toolchain and keep ``manifests/toolchain.txt`` in step with it (M0.3).

Usage (from the repository root)::

    python3 -m tools.toolchain.check_toolchain                   # check only
    python3 -m tools.toolchain.check_toolchain --write-manifest  # check, then rewrite manifest

The check prints one line per tool (status, name, version, path, detail): minimum versions
for the C++ and Python tools, Universal Ctags, exactly fbc 1.10.1 (through ``GEF_FBC`` or the
default path) and the SHA-256 of the fbc distribution tarball when it is present. It reports
the glibc version, compiles a one-line program with ``fbc -v`` to capture the backend
gcc/as/ld invocations, and compares the regenerated manifest with the committed one.

Exit codes: 0 every check passed; 1 at least one check failed (nothing is written then);
2 command-line usage error (argparse).
"""

from __future__ import annotations

import argparse
import difflib
import os
import re
import shutil
import subprocess
import sys
import tempfile
from collections.abc import Sequence
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from enum import StrEnum
from pathlib import Path

from tools.toolchain.fbc import (
    DEFAULT_FBC,
    FBC_ENV_VAR,
    FBC_TARBALL_SHA256,
    REPO_ROOT,
    REQUIRED_FBC_VERSION,
    FbcError,
    fbc_candidate,
    fbc_tarball,
    is_harmless_fbc_stderr_line,
    resolve_fbc,
)
from tools.toolchain.manifest_validation import sha256_file

DEFAULT_MANIFEST = REPO_ROOT / "manifests" / "toolchain.txt"
BUILD_DIR = REPO_ROOT / "build"

EXIT_OK = 0
EXIT_FAILED = 1

_TIMEOUT_S = 120
_NUMERIC_VERSION = r"(\d+(?:\.\d+)+)"
_MAX_DIFF_LINES = 12
_MAX_DIFF_WIDTH = 160


class Status(StrEnum):
    OK = "OK"
    FAIL = "FAIL"
    INFO = "INFO"
    SKIP = "SKIP"


@dataclass(frozen=True)
class ToolSpec:
    """A tool on PATH whose ``--version`` output must report at least ``minimum``."""

    name: str
    command: str
    version_re: re.Pattern[str]
    minimum: tuple[int, ...]
    install_hint: str
    version_args: tuple[str, ...] = ("--version",)


@dataclass(frozen=True)
class CheckResult:
    status: Status
    name: str
    version: str
    path: str
    detail: str

    def line(self) -> str:
        return f"{self.status:<5} {self.name:<13} {self.version:<9} {self.path}  {self.detail}"


def _spec(name: str, pattern: str, minimum: tuple[int, ...], hint: str) -> ToolSpec:
    return ToolSpec(name, name, re.compile(pattern, re.MULTILINE), minimum, hint)


TOOL_SPECS: tuple[ToolSpec, ...] = (
    _spec("gcc", rf"^gcc \(GCC\) {_NUMERIC_VERSION}", (16,), "install GCC (dnf install gcc-c++)"),
    _spec(
        "clang",
        rf"^clang version {_NUMERIC_VERSION}",
        (22,),
        "install Clang (dnf install clang)",
    ),
    _spec("cmake", rf"^cmake version {_NUMERIC_VERSION}", (4, 0), "install CMake"),
    _spec("ninja", rf"^{_NUMERIC_VERSION}$", (1, 11), "install Ninja (dnf install ninja-build)"),
    # The interpreter running this check is the one the Python tooling uses.
    ToolSpec(
        "python",
        sys.executable,
        re.compile(rf"^Python {_NUMERIC_VERSION}", re.MULTILINE),
        (3, 14),
        "run the Python tooling with Python >= 3.14",
    ),
    _spec("ruff", rf"^ruff {_NUMERIC_VERSION}", (0, 16), "pip install --user 'ruff>=0.16'"),
    _spec(
        "basedpyright",
        rf"^basedpyright {_NUMERIC_VERSION}",
        (1, 39),
        "pip install --user 'basedpyright>=1.39'",
    ),
    _spec("pytest", rf"^pytest {_NUMERIC_VERSION}", (9, 1), "pip install --user 'pytest>=9.1'"),
    _spec(
        "clang-tidy",
        rf"LLVM version {_NUMERIC_VERSION}",
        (22,),
        "install clang-tools-extra (dnf install clang-tools-extra)",
    ),
    _spec(
        "clang-format",
        rf"^clang-format version {_NUMERIC_VERSION}",
        (22,),
        "install clang-tools-extra (dnf install clang-tools-extra)",
    ),
    _spec(
        "ctags",
        rf"^Universal Ctags {_NUMERIC_VERSION}",
        (6, 0),
        "install Universal Ctags (dnf install ctags); Exuberant Ctags is not supported",
    ),
)


def parse_version(text: str) -> tuple[int, ...]:
    """``"16.2.1"`` -> ``(16, 2, 1)``."""
    if not re.fullmatch(r"\d+(?:\.\d+)*", text):
        raise ValueError(f"not a numeric version: {text!r}")
    return tuple(int(part) for part in text.split("."))


def version_at_least(version: tuple[int, ...], minimum: tuple[int, ...]) -> bool:
    """Compare versions, padding the shorter one with zeros."""
    width = max(len(version), len(minimum))
    return version + (0,) * (width - len(version)) >= minimum + (0,) * (width - len(minimum))


def format_version(version: tuple[int, ...]) -> str:
    return ".".join(str(part) for part in version)


def display_path(path: Path | str) -> str:
    """Path as recorded: repository-relative inside the repository, else ``~`` for home."""
    candidate = Path(path)
    if candidate.is_absolute() and candidate.is_relative_to(REPO_ROOT):
        return candidate.relative_to(REPO_ROOT).as_posix()
    return display_path_text(str(path))


def _c_locale_env() -> dict[str, str]:
    env = dict(os.environ)
    env["LC_ALL"] = "C"
    return env


def _run(argv: Sequence[str], cwd: Path | None = None) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        list(argv),
        capture_output=True,
        text=True,
        check=False,
        timeout=_TIMEOUT_S,
        cwd=cwd,
        env=_c_locale_env(),
    )


def evaluate_version_output(spec: ToolSpec, path: str, output: str) -> CheckResult:
    """Judge a tool's ``--version`` output against its spec."""
    minimum = format_version(spec.minimum)
    match = spec.version_re.search(output)
    if match is None:
        first = output.strip().splitlines()[0] if output.strip() else "<no output>"
        return CheckResult(
            Status.FAIL,
            spec.name,
            "?",
            path,
            f"unrecognised version output {first!r}; {spec.install_hint}",
        )
    found = match.group(1)
    if not version_at_least(parse_version(found), spec.minimum):
        return CheckResult(
            Status.FAIL,
            spec.name,
            found,
            path,
            f"version {found} is older than the required >= {minimum}; {spec.install_hint}",
        )
    return CheckResult(Status.OK, spec.name, found, path, f">= {minimum}")


def check_tool(spec: ToolSpec) -> CheckResult:
    exe = shutil.which(spec.command)
    if exe is None:
        return CheckResult(
            Status.FAIL,
            spec.name,
            "-",
            "-",
            f"`{spec.command}` not found on PATH; {spec.install_hint}",
        )
    try:
        proc = _run([exe, *spec.version_args])
    except (OSError, subprocess.TimeoutExpired) as exc:
        return CheckResult(Status.FAIL, spec.name, "-", exe, f"cannot run: {exc}")
    return evaluate_version_output(spec, display_path(exe), proc.stdout + proc.stderr)


def check_fbc() -> tuple[CheckResult, Path | None]:
    """Resolve the pinned fbc; on failure the detail says what is wrong and how to fix it."""
    candidate, origin = fbc_candidate()
    try:
        fbc = resolve_fbc()
    except FbcError as exc:
        detail = str(exc)
        if origin == FBC_ENV_VAR:
            detail += f" (or unset {FBC_ENV_VAR} to use the default {display_path(DEFAULT_FBC)})"
        return CheckResult(Status.FAIL, "fbc", "-", display_path(candidate), detail), None
    return (
        CheckResult(
            Status.OK,
            "fbc",
            REQUIRED_FBC_VERSION,
            display_path(fbc),
            f"== {REQUIRED_FBC_VERSION} (from {origin})",
        ),
        fbc,
    )


def check_fbc_tarball(tarball: Path, expected_sha256: str = FBC_TARBALL_SHA256) -> CheckResult:
    path = display_path(tarball)
    if not tarball.is_file():
        return CheckResult(
            Status.INFO, "fbc-tarball", "-", path, "tarball not found, hash not checked"
        )
    digest = sha256_file(tarball)
    if digest != expected_sha256:
        return CheckResult(
            Status.FAIL,
            "fbc-tarball",
            "-",
            path,
            f"SHA-256 {digest} does not match the pinned {expected_sha256}; "
            "replace it with the official FreeBASIC 1.10.1 linux-x86_64 tarball",
        )
    return CheckResult(Status.OK, "fbc-tarball", "-", path, f"SHA-256 matches {expected_sha256}")


def glibc_version() -> str:
    """The glibc version of this process, e.g. ``"2.43"``."""
    value = os.confstr("CS_GNU_LIBC_VERSION")
    if not value or not value.startswith("glibc "):
        raise RuntimeError(f"not a glibc system (CS_GNU_LIBC_VERSION={value!r})")
    return value.removeprefix("glibc ")


class CaptureError(RuntimeError):
    """``fbc -v`` did not produce the expected backend invocations."""


@dataclass(frozen=True)
class BackendCapture:
    """The normalised result of ``fbc -v hello.bas`` and the backend tool versions."""

    version_line: str
    target: str
    backend: str
    compile_c: str
    assemble: str
    link: str
    filtered_stderr: tuple[str, ...]
    gcc_version: str
    as_version: str
    ld_version: str


CAPTURE_SOURCE = "Print 1\n"
_CAPTURE_FIELDS = {
    "target": "target:",
    "backend": "backend:",
    "compile_c": "compiling C:",
    "assemble": "assembling:",
    "link": "linking:",
}


def _first_line(argv: Sequence[str]) -> str:
    proc = _run(argv)
    lines = proc.stdout.strip().splitlines()
    if proc.returncode != 0 or not lines:
        raise CaptureError(f"`{' '.join(argv)}` failed: {proc.stderr.strip()!r}")
    return lines[0]


def capture_fbc_backend(fbc: Path) -> BackendCapture:
    """Compile ``Print 1`` with ``fbc -v`` in a scratch directory under ``build/``.

    Machine-specific paths are normalised: the scratch directory to ``<WORKDIR>``, fbc's
    ``bin`` directory to ``<FBC_BIN>`` and the home directory to ``~``.
    """
    BUILD_DIR.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="fbc_capture_", dir=BUILD_DIR) as tmp:
        workdir = Path(tmp)
        (workdir / "hello.bas").write_text(CAPTURE_SOURCE, encoding="ascii")
        proc = _run([str(fbc), "-v", "hello.bas"], cwd=workdir)

        replacements = [
            (str(workdir), "<WORKDIR>"),
            (str(workdir.resolve()), "<WORKDIR>"),
            (str(fbc.parent), "<FBC_BIN>"),
            (str(fbc.resolve().parent), "<FBC_BIN>"),
        ]

        def normalise(text: str) -> str:
            for old, new in replacements:
                text = text.replace(old, new)
            return display_path_text(text)

        stderr_lines = [ln for ln in proc.stderr.splitlines() if ln.strip()]
        unexpected = [ln for ln in stderr_lines if not is_harmless_fbc_stderr_line(ln)]
        if proc.returncode != 0 or unexpected:
            raise CaptureError(
                f"`fbc -v hello.bas` failed (exit {proc.returncode}): "
                f"{normalise(chr(10).join(unexpected) or proc.stdout)!r}"
            )
        stdout = [normalise(ln) for ln in proc.stdout.splitlines()]
        fields: dict[str, str] = {}
        for key, prefix in _CAPTURE_FIELDS.items():
            values = [ln.removeprefix(prefix).strip() for ln in stdout if ln.startswith(prefix)]
            if len(values) != 1:
                raise CaptureError(f"expected one {prefix!r} line in `fbc -v` output: {stdout}")
            fields[key] = values[0]
        version_lines = [ln for ln in stdout if ln.startswith("FreeBASIC Compiler - Version")]
        if len(version_lines) != 1:
            raise CaptureError(f"no fbc version line in `fbc -v` output: {stdout}")

        run = _run([str(workdir / "hello")], cwd=workdir)
        if run.returncode != 0 or run.stdout.strip() != "1":
            raise CaptureError(
                f"the compiled `Print 1` program printed {run.stdout!r} (exit {run.returncode})"
            )

    return BackendCapture(
        version_line=version_lines[0],
        target=fields["target"],
        backend=fields["backend"],
        compile_c=fields["compile_c"],
        assemble=fields["assemble"],
        link=fields["link"],
        filtered_stderr=tuple(normalise(ln) for ln in stderr_lines),
        gcc_version=_first_line(["gcc", "--version"]),
        as_version=_first_line(["as", "--version"]),
        ld_version=_first_line(["ld", "--version"]),
    )


def display_path_text(text: str) -> str:
    """Write the home directory as ``~`` wherever it occurs in ``text``."""
    home = str(Path.home())
    if text == home:
        return "~"
    return text.replace(home + os.sep, "~" + os.sep)


def render_manifest(
    tools: Sequence[CheckResult], tarball: CheckResult, glibc: str, capture: BackendCapture
) -> str:
    """The deterministic content of ``manifests/toolchain.txt``."""
    table = [f"{t.name:<13} {t.version:<9} {t.path}" for t in tools]
    harmless = [f"  {ln}" for ln in capture.filtered_stderr] or ["  (none on this run)"]
    lines = [
        "# GEF C++ port: pinned toolchain manifest (M0.3).",
        "#",
        "# Records the versions of the build, lint and test tools, the glibc version, and how",
        "# fbc 1.10.1 drives its gcc backend (captured with `fbc -v` on the one-line program",
        "# `Print 1`). The exact-mode C++ build mirrors the backend gcc flags recorded here.",
        "#",
        "# Generated by `python3 -m tools.toolchain.check_toolchain --write-manifest`;",
        "# do not edit by hand.",
        "# `python3 -m tools.toolchain.check_toolchain` regenerates this content from the live",
        "# toolchain and fails if it differs from this file. The content is deterministic:",
        "# the home directory is written as ~, fbc's bin directory as <FBC_BIN> and the scratch",
        "# compile directory (a temporary directory under build/) as <WORKDIR>.",
        "",
        "[tools]",
        f"{'name':<13} {'version':<9} path",
        *table,
        f"{'glibc':<13} {glibc}",
        "",
        "[fbc]",
        f"version line: {capture.version_line}",
        f"tarball:      {tarball.path}: {tarball.detail}",
        "",
        "[fbc -v backend capture]",
        f"source:       hello.bas containing `{CAPTURE_SOURCE.strip()}`, compiled in <WORKDIR>",
        "command:      fbc -v hello.bas",
        f"target:       {capture.target}",
        f"backend:      {capture.backend}",
        f"compile C:    {capture.compile_c}",
        f"assemble:     {capture.assemble}",
        f"link:         {capture.link}",
        "",
        "[backend tool versions (first line of --version)]",
        f"gcc:          {capture.gcc_version}",
        f"as:           {capture.as_version}",
        f"ld:           {capture.ld_version}",
        "",
        "[filtered fbc stderr]",
        "# fbc prints these dynamic-loader warnings on every invocation. They are filtered out",
        "# of all tool output and are harmless: the prebuilt fbc was linked against an older",
        "# ncurses (libtinfo.so.5) whose `ospeed` symbol has a different size; compilation and",
        "# the compiled programs are unaffected.",
        *harmless,
    ]
    return "\n".join(lines) + "\n"


def compare_manifest(manifest: Path, expected: str) -> tuple[CheckResult, list[str]]:
    """Compare the committed manifest with the live content; also returns the differing lines."""
    path = display_path(manifest)
    hint = "rerun with --write-manifest"
    if not manifest.is_file():
        return CheckResult(Status.FAIL, "manifest", "-", path, f"missing; {hint}"), []
    current = manifest.read_text(encoding="utf-8")
    if current == expected:
        ok = CheckResult(Status.OK, "manifest", "-", path, "up to date with the live toolchain")
        return ok, []
    diff = difflib.unified_diff(
        current.splitlines(), expected.splitlines(), "committed", "live", lineterm="", n=0
    )
    changed = [ln for ln in diff if ln[:1] in "+-" and not ln.startswith(("+++", "---"))]
    detail = f"out of date with the live toolchain ({len(changed)} differing lines); {hint}"
    return CheckResult(Status.FAIL, "manifest", "-", path, detail), changed


def run_checks(manifest: Path, write: bool) -> int:
    results: list[CheckResult] = []

    def emit(result: CheckResult) -> None:
        results.append(result)
        print(result.line(), flush=True)

    with ThreadPoolExecutor(max_workers=len(TOOL_SPECS)) as pool:
        tool_results = list(pool.map(check_tool, TOOL_SPECS))
    for result in tool_results:
        emit(result)

    fbc_result, fbc = check_fbc()
    emit(fbc_result)
    tool_results.append(fbc_result)
    if fbc is not None:
        tarball = check_fbc_tarball(fbc_tarball(fbc))
    else:
        tarball = CheckResult(
            Status.SKIP, "fbc-tarball", "-", "-", "not checked because fbc was not resolved"
        )
    emit(tarball)

    glibc = glibc_version()
    emit(CheckResult(Status.INFO, "glibc", glibc, "-", "C library of this Python process"))

    capture: BackendCapture | None = None
    if fbc is not None:
        try:
            capture = capture_fbc_backend(fbc)
        except (CaptureError, OSError, subprocess.TimeoutExpired) as exc:
            emit(CheckResult(Status.FAIL, "fbc-backend", "-", "-", str(exc)))
        else:
            emit(
                CheckResult(
                    Status.OK, "fbc-backend", "-", "-", f"captured: {capture.compile_c[:60]}..."
                )
            )

    failed = [r.name for r in results if r.status is Status.FAIL]
    if failed or capture is None:
        emit(
            CheckResult(
                Status.SKIP,
                "manifest",
                "-",
                display_path(manifest),
                "not compared/written because other checks failed",
            )
        )
    else:
        content = render_manifest(tool_results, tarball, glibc, capture)
        if write:
            manifest.parent.mkdir(parents=True, exist_ok=True)
            manifest.write_text(content, encoding="utf-8")
            print(f"wrote {display_path(manifest)}")
        comparison, changed = compare_manifest(manifest, content)
        emit(comparison)
        for line in changed[:_MAX_DIFF_LINES]:
            print(f"      {line[:_MAX_DIFF_WIDTH]}")
        if len(changed) > _MAX_DIFF_LINES:
            print(f"      ... {len(changed) - _MAX_DIFF_LINES} more differing lines")
        failed = [r.name for r in results if r.status is Status.FAIL]

    if failed:
        print(f"toolchain check FAILED: {', '.join(failed)}")
        return EXIT_FAILED
    print(f"toolchain check passed ({len(results)} checks)")
    return EXIT_OK


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="python3 -m tools.toolchain.check_toolchain",
        description="Check the pinned toolchain and the committed toolchain manifest.",
        epilog="exit codes: 0 all checks passed; 1 a check failed; 2 usage error",
    )
    parser.add_argument(
        "--write-manifest",
        action="store_true",
        help="(re)write the manifest from the live toolchain when every check passes",
    )
    parser.add_argument(
        "--manifest",
        type=Path,
        default=DEFAULT_MANIFEST,
        help="manifest path (default: <repo>/manifests/toolchain.txt)",
    )
    args = parser.parse_args(argv)
    manifest: Path = args.manifest
    write: bool = args.write_manifest
    return run_checks(manifest, write)


if __name__ == "__main__":
    sys.exit(main())
