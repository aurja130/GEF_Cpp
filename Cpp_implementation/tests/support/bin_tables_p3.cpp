// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

#include "support/bin_tables_p3.hpp"

#include "support/golden.hpp"

#include <array>
#include <concepts>
#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <optional>
#include <stdexcept>
#include <string>
#include <string_view>
#include <utility>
#include <variant>
#include <vector>

namespace gef::test {

namespace {

// The 47 working copies by their BASIC names (GEF.bas:1399-1445, P3 group "working parameter
// set").
struct WorkingName {
    std::string_view name;
    float tables::WorkingParameters::* member;
};
using W = tables::WorkingParameters;
constexpr std::array<WorkingName, 47> working_names{{
    {.name = "P_DZ_Mean_S1", .member = &W::p_dz_mean_s1},
    {.name = "P_corr_S1", .member = &W::p_corr_s1},
    {.name = "P_DZ_Mean_S2", .member = &W::p_dz_mean_s2},
    {.name = "P_DZ_Mean_S3", .member = &W::p_dz_mean_s3},
    {.name = "P_DZ_Mean_S4", .member = &W::p_dz_mean_s4},
    {.name = "P_DZ_Mean_SL5", .member = &W::p_dz_mean_sl5},
    {.name = "P_DZ_Mean_S5", .member = &W::p_dz_mean_s5},
    {.name = "P_Z_Curv_S1", .member = &W::p_z_curv_s1},
    {.name = "P_Z_Curv_S2", .member = &W::p_z_curv_s2},
    {.name = "S2leftmod", .member = &W::s2leftmod},
    {.name = "P_A_Width_S2", .member = &W::p_a_width_s2},
    {.name = "P_Z_Curv_S3", .member = &W::p_z_curv_s3},
    {.name = "P_Z_Curv_S4", .member = &W::p_z_curv_s4},
    {.name = "P_Z_Curv_SL5", .member = &W::p_z_curv_sl5},
    {.name = "P_Z_Curv_S5", .member = &W::p_z_curv_s5},
    {.name = "PZ_S3_olap_pos", .member = &W::pz_s3_olap_pos},
    {.name = "PZ_S3_olap_curv", .member = &W::pz_s3_olap_curv},
    {.name = "Delta_S0", .member = &W::delta_s0},
    {.name = "P_Shell_S1", .member = &W::p_shell_s1},
    {.name = "P_Shell_S2", .member = &W::p_shell_s2},
    {.name = "P_Shell_S3", .member = &W::p_shell_s3},
    {.name = "P_Shell_S4", .member = &W::p_shell_s4},
    {.name = "P_Shell_SL5", .member = &W::p_shell_sl5},
    {.name = "P_Shell_S5", .member = &W::p_shell_s5},
    {.name = "dE_Defo_S1", .member = &W::de_defo_s1},
    {.name = "dE_Defo_S2", .member = &W::de_defo_s2},
    {.name = "dE_Defo_S3", .member = &W::de_defo_s3},
    {.name = "dE_Defo_S4", .member = &W::de_defo_s4},
    {.name = "dE_Defo_S5", .member = &W::de_defo_s5},
    {.name = "betaL0", .member = &W::betal0},
    {.name = "betaL1", .member = &W::betal1},
    {.name = "betaH0", .member = &W::betah0},
    {.name = "betaH1", .member = &W::betah1},
    {.name = "dbeta_S3", .member = &W::dbeta_s3},
    {.name = "T_low_S1", .member = &W::t_low_s1},
    {.name = "T_low_S2", .member = &W::t_low_s2},
    {.name = "T_low_S3", .member = &W::t_low_s3},
    {.name = "T_low_S4", .member = &W::t_low_s4},
    {.name = "T_low_S5", .member = &W::t_low_s5},
    {.name = "T_low_SL", .member = &W::t_low_sl},
    {.name = "ECOLLFRAC", .member = &W::ecollfrac},
    {.name = "EDISSFRAC", .member = &W::edissfrac},
    {.name = "P_att_pol", .member = &W::p_att_pol},
    {.name = "P_att_rel", .member = &W::p_att_rel},
    {.name = "HOMPOL", .member = &W::hompol},
    {.name = "POLARadd", .member = &W::polaradd},
    {.name = "Jscaling", .member = &W::jscaling},
}};

// Calls v.single(name, float&), v.integer(name, integral&) and v.array(name, fb::Array&) for
// every variable of `c` under its P3 name. `Case` is BuilderCase or BuilderCase const.
template <typename Case, typename Visitor>
void visit(Case& c, Visitor& v) {
    // bin loop counters and limits
    v.integer("I_E_distr", c.bin.i_e_distr);
    v.integer("I_N_Multi", c.bin.i_n_multi);
    v.integer("I_Z_Multi", c.bin.i_z_multi);
    v.integer("I_E_Multi", c.bin.i_e_multi);
    v.integer("N_E_distr", c.bin.n_e_distr);
    v.integer("N_N_Multi", c.bin.n_n_multi);
    v.integer("N_Z_Multi", c.bin.n_z_multi);
    v.integer("N_E_Multi", c.bin.n_e_multi);
    v.integer("I_N_Multi_Max", c.bin.i_n_multi_max);
    v.integer("I_Z_Multi_Max", c.bin.i_z_multi_max);
    v.integer("I_A_Multi", c.bin.i_a_multi);
    // bin inputs (Emode is a nominal parameter, below)
    v.integer("P_Z_CN", c.plan.p_z_cn);
    v.integer("P_A_CN", c.plan.p_a_cn);
    v.single("P_E_exc", c.plan.p_e_exc);
    v.integer("I_Z_CN", c.bin.i_z_cn);
    v.integer("I_A_CN", c.bin.i_a_cn);
    v.integer("I_N_CN", c.tables.i_n_cn);
    v.single("R_E_exc_used", c.bin.r_e_exc_used);
    v.single("R_NEVTspectrum", c.bin.r_nevtspectrum);
    v.single("Eabsgs", c.plan.eabsgs);
    v.single("Spin_CN", c.spin_cn);
    v.single("I_rigid_spher", c.bin.i_rigid_spher);
    v.single("I_eff_CN", c.bin.i_eff_cn);
    v.single("E_rot_CN", c.bin.e_rot_cn);
    v.integer("NEVTtot", c.plan.nevttot);
    v.integer("NEVTused", c.bin.nevtused);
    v.integer("IEVTtot", c.bin.ievttot);
    v.integer("Inofirst", c.plan.inofirst);
    v.integer("Imulti", c.imulti);
    v.single("Escission_lim", c.tables.escission_lim);
    // mode centres, mean Z, mean A and N of the modes
    v.single("ZC_Mode_0", c.tables.zc_mode_0);
    v.single("ZC_Mode_1", c.tables.zc_mode_1);
    v.single("ZC_Mode_2", c.tables.zc_mode_2);
    v.single("ZC_Mode_3", c.tables.zc_mode_3);
    v.single("ZC_Mode_4", c.tables.zc_mode_4);
    v.single("ZC_Mode_5", c.tables.zc_mode_5);
    v.single("ZC_Mode_3_shift", c.tables.zc_mode_3_shift);
    v.single("P_Z_Mean_S1", c.tables.p_z_mean_s1);
    v.single("P_Z_Mean_S2", c.tables.p_z_mean_s2);
    v.single("P_Z_Mean_S3", c.tables.p_z_mean_s3);
    v.single("P_Z_Mean_S4", c.tables.p_z_mean_s4);
    v.single("P_Z_Mean_S5", c.tables.p_z_mean_s5);
    v.single("AC_Mode_0", c.tables.ac_mode_0);
    v.single("AC_Mode_1", c.tables.ac_mode_1);
    v.single("AC_Mode_2", c.tables.ac_mode_2);
    v.single("AC_Mode_3", c.tables.ac_mode_3);
    v.single("AC_Mode_4", c.tables.ac_mode_4);
    v.single("AC_Mode_5", c.tables.ac_mode_5);
    v.single("NC_Mode_0", c.tables.nc_mode_0);
    v.single("NC_Mode_1", c.tables.nc_mode_1);
    v.single("NC_Mode_2", c.tables.nc_mode_2);
    v.single("NC_Mode_3", c.tables.nc_mode_3);
    v.single("NC_Mode_4", c.tables.nc_mode_4);
    v.single("NC_Mode_5", c.tables.nc_mode_5);
    v.single("RZpol", c.tables.rzpol);
    v.single("RA", c.tables.ra);
    v.single("ZUCD", c.tables.zucd);
    // curvatures
    v.single("R_Z_Curv_S0", c.tables.r_z_curv_s0);
    v.single("R_Z_Curv1_S0", c.tables.r_z_curv1_s0);
    v.single("R_A_Curv1_S0", c.tables.r_a_curv1_s0);
    v.single("R_Z_Curv2_S0", c.tables.r_z_curv2_s0);
    v.single("R_A_Curv2_S0", c.tables.r_a_curv2_s0);
    // stale temporaries
    v.single("beta1", c.temporaries.beta1);
    v.single("beta2", c.temporaries.beta2);
    v.single("rbeta", c.temporaries.rbeta);
    v.single("beta1_opt", c.temporaries.beta1_opt);
    v.single("beta2_opt", c.temporaries.beta2_opt);
    v.single("beta1_prev", c.temporaries.beta1_prev);
    v.single("beta2_prev", c.temporaries.beta2_prev);
    v.single("E_defo", c.temporaries.e_defo);
    v.single("Z1", c.temporaries.z1);
    v.single("Z2", c.temporaries.z2);
    v.single("A1", c.temporaries.a1);
    v.single("A2", c.temporaries.a2);
    v.integer("IZ1", c.temporaries.iz1);
    v.integer("IZ2", c.temporaries.iz2);
    v.single("Z", c.z);
    // persistent per-fragment tables
    v.array("beta", c.tables.beta);
    v.array("Edefo", c.tables.edefo);
    v.array("Zmean", c.tables.zmean);
    v.array("Zshift", c.tables.zshift);
    // working parameter set
    for (WorkingName const& w : working_names) {
        v.single(w.name, c.working.*w.member);
    }
    // nominal parameters: the never-perturbed ones (and Emode) appear in P3 under these names;
    // the perturbed nominal values (`_P_DZ_Mean_S1`, ...) do not
    for (params::NominalParameter const& p : params::nominal_parameters) {
        std::visit([&](auto member) { v.single_or_integer(p.name, c.params.*member); }, p.member);
    }
    // read before written, not in P3
    v.integer("f", c.f);
}

struct NameCollector {
    std::set<std::string, std::less<>> names;
    void single(std::string_view name, float const& /*value*/) { add(name); }
    template <std::integral T>
    void integer(std::string_view name, T const& /*value*/) {
        add(name);
    }
    template <typename T>
    void single_or_integer(std::string_view name, T const& /*value*/) {
        add(name);
    }
    template <typename A>
    void array(std::string_view name, A const& /*value*/) {
        add(name);
    }
    void add(std::string_view name) {
        if (!names.emplace(name).second) {
            throw std::logic_error("BuilderCase variable registered twice: " + std::string(name));
        }
    }
};

struct Loader {
    ProbeRecord const* record;
    void single(std::string_view name, float& value) const {
        if (record->has(name)) {
            value = single_value(*record, name);
        }
    }
    template <std::integral T>
    void integer(std::string_view name, T& value) const {
        if (record->has(name)) {
            std::int64_t const v = integer_value(*record, name);
            if (!std::in_range<T>(v)) {
                throw std::runtime_error(std::string(name) + " out of range in " + record->context);
            }
            value = static_cast<T>(v);
        }
    }
    template <typename T>
    void single_or_integer(std::string_view name, T& value) const {
        if constexpr (std::same_as<T, float>) {
            single(name, value);
        } else {
            integer(name, value);
        }
    }
    template <std::size_t rank>
    void array(std::string_view name, fb::Array<float, rank>& value) const {
        if (record->has(name)) {
            load_single_array(*record, name, value);
        }
    }
};

struct Dumper {
    ProbeDump* dump;
    bool with_arrays;
    void single(std::string_view name, float value) const { dump->scalar(name, value); }
    template <std::integral T>
    void integer(std::string_view name, T value) const {
        dump->scalar(name, static_cast<std::int64_t>(value));
    }
    template <typename T>
    void single_or_integer(std::string_view name, T value) const {
        if constexpr (std::same_as<T, float>) {
            single(name, value);
        } else {
            integer(name, value);
        }
    }
    template <typename A>
    void array(std::string_view name, A const& value) const {
        if (with_arrays) {
            dump->array(name, value, true);
        }
    }
};

std::vector<std::string> split_ws(std::string const& line) {
    std::vector<std::string> fields;
    std::size_t at = 0;
    while (at < line.size()) {
        std::size_t const start = line.find_first_not_of(" \t", at);
        if (start == std::string::npos) {
            break;
        }
        std::size_t const end = line.find_first_of(" \t", start);
        fields.push_back(line.substr(start, end == std::string::npos ? end : end - start));
        at = end == std::string::npos ? line.size() : end;
    }
    return fields;
}

} // namespace

std::vector<std::string_view> const& working_parameter_names() {
    static std::vector<std::string_view> const names = [] {
        std::vector<std::string_view> out;
        out.reserve(working_names.size());
        for (WorkingName const& w : working_names) {
            out.push_back(w.name);
        }
        return out;
    }();
    return names;
}

void fill_working(tables::WorkingParameters& w, float value) {
    for (WorkingName const& name : working_names) {
        w.*name.member = value;
    }
}

std::set<std::string, std::less<>> const& builder_variable_names() {
    static std::set<std::string, std::less<>> const names = [] {
        BuilderCase const c;
        NameCollector collector;
        visit(c, collector);
        return collector.names;
    }();
    return names;
}

void load_builder_case(ProbeRecord const& record, BuilderCase& c) {
    Loader loader{&record};
    visit(c, loader);
}

ProbeDump dump_builder_case(BuilderCase const& c, std::string_view id, std::string_view context,
                            bool with_arrays) {
    ProbeDump dump{std::string(id), std::string(context)};
    Dumper dumper{.dump = &dump, .with_arrays = with_arrays};
    visit(c, dumper);
    return dump;
}

std::map<std::string, LastWriter, std::less<>> const& last_writer_map() {
    static std::map<std::string, LastWriter, std::less<>> const map = [] {
        std::map<std::string, LastWriter, std::less<>> out;
        std::filesystem::path const path =
            std::filesystem::path(GEF_TEST_REPO_DIR) / "harness/inputs/m7/last_writer.tsv";
        for (std::string const& line : read_lines(path)) {
            if (line.empty() || line.starts_with('#')) {
                continue;
            }
            std::vector<std::string> fields = split_ws(line);
            if (fields.size() < 4) {
                throw std::runtime_error("last_writer.tsv: bad line: " + line);
            }
            LastWriter row{.part = fields.at(2), .writers = {}};
            if (fields.at(3) != "-") {
                row.writers.assign(fields.begin() + 3, fields.end());
            }
            out.emplace(fields.at(0), std::move(row));
        }
        return out;
    }();
    return map;
}

std::vector<std::string> const& m7_corpus_ids() {
    static std::vector<std::string> const ids = [] {
        std::vector<std::string> out;
        for (std::string const& line : read_lines(golden_file("m7-p3", "fingerprints.txt"))) {
            if (line.empty() || line.starts_with('#')) {
                continue;
            }
            std::string const id = line.substr(0, line.find(' '));
            if (out.empty() || out.back() != id) {
                out.push_back(id);
            }
        }
        return out;
    }();
    return ids;
}

std::filesystem::path capture_file(std::string const& capture, std::string_view file) {
    std::optional<std::filesystem::path> const path = store_file(capture, file);
    if (!path) {
        throw std::runtime_error("reference store: no " + std::string(file) + " in " + capture);
    }
    return *path;
}

} // namespace gef::test
