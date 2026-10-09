// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

#include "analysis/analyzer_registry.hpp"

#include <cstdint>

namespace gef::analysis {

// GEF.bas:726-737 Constructor Analyzer_Attributes (the R_ALim elements it does not set are 0).
AnalyzerAttributes::AnalyzerAttributes() : r_alim({fb::Bounds{1, 4}, fb::Bounds{1, 3}}) {
    r_alim(1, 1) = 0.0F; // first bin (or element of array)
    r_alim(1, 3) = 1.0F; // binsize
    r_alim(2, 1) = 0.0F;
    r_alim(2, 3) = 1.0F;
    r_alim(3, 1) = 0.0F;
    r_alim(3, 3) = 1.0F;
    r_alim(4, 1) = 0.0F;
    r_alim(4, 3) = 1.0F;
}

// The statements below are those of the emitted C (GEF.c of the default build, 25215-30202),
// one by one; each carries the BASIC line it comes from. The histogram arrays dimensioned in
// between belong to M13.

namespace {

// The Spectra.bas section included at GEF.bas:1278.
void spectra_bas_analyzers(AnalyzerRegistry& reg, std::int64_t& i_anl) {
    auto par = [&reg](std::int64_t i) -> AnalyzerAttributes& { return reg.anl_par(i); };
    i_anl = i_anl + 1;                                                // Spectra.bas:6
    par(i_anl).c_name = "EMpot";                                      // Spectra.bas:7
    par(i_anl).c_title = "Potential energy for first-chance fission"; // Spectra.bas:8
    par(i_anl).c_xaxis = "Fragment atomic number";                    // Spectra.bas:9
    par(i_anl).c_yaxis = "E / MeV";                                   // Spectra.bas:10
    par(i_anl).c_linesymbol = "LTBR1";                                // Spectra.bas:11
    par(i_anl).c_type = "digital";                                    // Spectra.bas:12

    i_anl = i_anl + 1;                        // Spectra.bas:17
    par(i_anl).c_name = "Emultichance";       // Spectra.bas:18
    par(i_anl).c_title = "E* at fission";     // Spectra.bas:19
    par(i_anl).c_xaxis = "Ee$x$c$ / MeV";     // Spectra.bas:20
    par(i_anl).c_yaxis = "Probability";       // Spectra.bas:21
    par(i_anl).r_alim(1, 1) = 0x1.99999Ap-4F; // Spectra.bas:22
    par(i_anl).r_alim(1, 3) = 0x1.99999Ap-4F; // Spectra.bas:23
    par(i_anl).c_linesymbol = "HTB0";         // Spectra.bas:24
    par(i_anl).c_type = "digital";            // Spectra.bas:25

    i_anl = i_anl + 1;                                       // Spectra.bas:30
    par(i_anl).c_name = "ZPROV";                             // Spectra.bas:31
    par(i_anl).c_title = "Provisional element distribution"; // Spectra.bas:32
    par(i_anl).c_xaxis = "Atomic number";                    // Spectra.bas:33
    par(i_anl).c_yaxis = "Yield";                            // Spectra.bas:34
    par(i_anl).c_linesymbol = "LTR11";                       // Spectra.bas:35
    par(i_anl).c_type = "digital";                           // Spectra.bas:36

    i_anl = i_anl + 1;                                       // Spectra.bas:39
    par(i_anl).c_name = "ZMPROV";                            // Spectra.bas:40
    par(i_anl).c_title = "Provisional element distribution"; // Spectra.bas:41
    par(i_anl).c_xaxis = "Atomic number";                    // Spectra.bas:42
    par(i_anl).c_yaxis = "Yield";                            // Spectra.bas:43
    par(i_anl).c_linesymbol = "RBT1";                        // Spectra.bas:44
    par(i_anl).c_type = "digital";                           // Spectra.bas:45

    i_anl = i_anl + 1;                                         // Spectra.bas:48
    par(i_anl).c_name = "NZPOST";                              // Spectra.bas:49
    par(i_anl).c_title = "Nuclide distribution, post-neutron"; // Spectra.bas:50
    par(i_anl).c_xaxis = "Neutron number";                     // Spectra.bas:51
    par(i_anl).c_yaxis = "Atomic number";                      // Spectra.bas:52
    par(i_anl).c_type = "digital";                             // Spectra.bas:53

    i_anl = i_anl + 1;                                         // Spectra.bas:83
    par(i_anl).c_name = "ZPOST";                               // Spectra.bas:84
    par(i_anl).c_title = "Element distribution, post-neutron"; // Spectra.bas:85
    par(i_anl).c_xaxis = "Atomic number";                      // Spectra.bas:86
    par(i_anl).c_yaxis = "Yield";                              // Spectra.bas:87
    par(i_anl).c_linesymbol = "RT11";                          // Spectra.bas:88
    par(i_anl).c_type = "digital";                             // Spectra.bas:89

    i_anl = i_anl + 1;                                         // Spectra.bas:92
    par(i_anl).c_name = "ZMPOST";                              // Spectra.bas:93
    par(i_anl).c_title = "Element distribution, post-neutron"; // Spectra.bas:94
    par(i_anl).c_xaxis = "Atomic number";                      // Spectra.bas:95
    par(i_anl).c_yaxis = "Yield";                              // Spectra.bas:96
    par(i_anl).c_linesymbol = "RBT1";                          // Spectra.bas:97
    par(i_anl).c_type = "digital";                             // Spectra.bas:98

    i_anl = i_anl + 1;                                               // Spectra.bas:101
    par(i_anl).c_name = "NPRE";                                      // Spectra.bas:102
    par(i_anl).c_title = "Neutron-number distribution, pre-neutron"; // Spectra.bas:103
    par(i_anl).c_xaxis = "Neutron number";                           // Spectra.bas:104
    par(i_anl).c_yaxis = "Yield";                                    // Spectra.bas:105
    par(i_anl).c_linesymbol = "RT11";                                // Spectra.bas:106
    par(i_anl).c_type = "digital";                                   // Spectra.bas:107

    i_anl = i_anl + 1;                                               // Spectra.bas:110
    par(i_anl).c_name = "NMPRE";                                     // Spectra.bas:111
    par(i_anl).c_title = "Neutron-number distribution, pre-neutron"; // Spectra.bas:112
    par(i_anl).c_xaxis = "Neutron number";                           // Spectra.bas:113
    par(i_anl).c_yaxis = "Yield";                                    // Spectra.bas:114
    par(i_anl).c_linesymbol = "RBT1";                                // Spectra.bas:115
    par(i_anl).c_type = "digital";                                   // Spectra.bas:116

    i_anl = i_anl + 1;                                                // Spectra.bas:119
    par(i_anl).c_name = "NPOST";                                      // Spectra.bas:120
    par(i_anl).c_title = "Neutron-number distribution, post-neutron"; // Spectra.bas:121
    par(i_anl).c_xaxis = "Neutron number";                            // Spectra.bas:122
    par(i_anl).c_yaxis = "Yield";                                     // Spectra.bas:123
    par(i_anl).c_linesymbol = "RT11";                                 // Spectra.bas:124
    par(i_anl).c_type = "digital";                                    // Spectra.bas:125

    i_anl = i_anl + 1;                                                // Spectra.bas:128
    par(i_anl).c_name = "NMPOST";                                     // Spectra.bas:129
    par(i_anl).c_title = "Neutron-number distribution, post-neutron"; // Spectra.bas:130
    par(i_anl).c_xaxis = "Neutron number";                            // Spectra.bas:131
    par(i_anl).c_yaxis = "Yield";                                     // Spectra.bas:132
    par(i_anl).c_linesymbol = "RBT1";                                 // Spectra.bas:133
    par(i_anl).c_type = "digital";                                    // Spectra.bas:134

    i_anl = i_anl + 1;                                      // Spectra.bas:137
    par(i_anl).c_name = "APOST";                            // Spectra.bas:138
    par(i_anl).c_title = "Mass distribution, post-neutron"; // Spectra.bas:139
    par(i_anl).c_xaxis = "Mass number";                     // Spectra.bas:140
    par(i_anl).c_yaxis = "Yield";                           // Spectra.bas:141
    par(i_anl).c_linesymbol = "BT11";                       // Spectra.bas:142
    par(i_anl).c_type = "digital";                          // Spectra.bas:143

    i_anl = i_anl + 1;                                      // Spectra.bas:146
    par(i_anl).c_name = "AMPOST";                           // Spectra.bas:147
    par(i_anl).c_title = "Mass distribution, post-neutron"; // Spectra.bas:148
    par(i_anl).c_xaxis = "Mass number";                     // Spectra.bas:149
    par(i_anl).c_yaxis = "Yield";                           // Spectra.bas:150
    par(i_anl).c_linesymbol = "GT1";                        // Spectra.bas:151
    par(i_anl).c_type = "digital";                          // Spectra.bas:152

    i_anl = i_anl + 1;                                                 // Spectra.bas:155
    par(i_anl).c_name = "APROV";                                       // Spectra.bas:156
    par(i_anl).c_title = "Provisional mass distribution, pre-neutron"; // Spectra.bas:157
    par(i_anl).c_xaxis = "Mass number";                                // Spectra.bas:158
    par(i_anl).c_yaxis = "Yield";                                      // Spectra.bas:159
    par(i_anl).c_linesymbol = "GT11";                                  // Spectra.bas:160
    par(i_anl).c_type = "digital";                                     // Spectra.bas:161

    i_anl = i_anl + 1;                                                 // Spectra.bas:164
    par(i_anl).c_name = "AMPROV";                                      // Spectra.bas:165
    par(i_anl).c_title = "Provisional mass distribution, pre-neutron"; // Spectra.bas:166
    par(i_anl).c_xaxis = "Mass number";                                // Spectra.bas:167
    par(i_anl).c_yaxis = "Yield";                                      // Spectra.bas:168
    par(i_anl).c_linesymbol = "GT1";                                   // Spectra.bas:169
    par(i_anl).c_type = "digital";                                     // Spectra.bas:170

    i_anl = i_anl + 1;                                     // Spectra.bas:173
    par(i_anl).c_name = "APRE";                            // Spectra.bas:174
    par(i_anl).c_title = "Mass distribution, pre-neutron"; // Spectra.bas:175
    par(i_anl).c_xaxis = "Mass number";                    // Spectra.bas:176
    par(i_anl).c_yaxis = "Yield";                          // Spectra.bas:177
    par(i_anl).c_linesymbol = "GT11";                      // Spectra.bas:178
    par(i_anl).c_type = "digital";                         // Spectra.bas:179

    i_anl = i_anl + 1;                                     // Spectra.bas:182
    par(i_anl).c_name = "AMPRE";                           // Spectra.bas:183
    par(i_anl).c_title = "Mass distribution, pre-neutron"; // Spectra.bas:184
    par(i_anl).c_xaxis = "Mass number";                    // Spectra.bas:185
    par(i_anl).c_yaxis = "Yield";                          // Spectra.bas:186
    par(i_anl).c_linesymbol = "GT1";                       // Spectra.bas:187
    par(i_anl).c_type = "digital";                         // Spectra.bas:188

    i_anl = i_anl + 1;                                                     // Spectra.bas:191
    par(i_anl).c_name = "ZISOPRE";                                         // Spectra.bas:192
    par(i_anl).c_title = "Isobaric Z distribution for A = &, pre-neutron"; // Spectra.bas:193
    par(i_anl).c_xaxis = "Mass number";                                    // Spectra.bas:194
    par(i_anl).c_yaxis = "Atomic number";                                  // Spectra.bas:195
    par(i_anl).c_linesymbol = "LRT11";                                     // Spectra.bas:196
    par(i_anl).c_type = "digital";                                         // Spectra.bas:197

    i_anl = i_anl + 1;                                                      // Spectra.bas:223
    par(i_anl).c_name = "ZISOPOST";                                         // Spectra.bas:224
    par(i_anl).c_title = "Isobaric Z distribution for A = &, post-neutron"; // Spectra.bas:225
    par(i_anl).c_xaxis = "Mass number";                                     // Spectra.bas:226
    par(i_anl).c_yaxis = "Atomic number";                                   // Spectra.bas:227
    par(i_anl).c_linesymbol = "LRT11";                                      // Spectra.bas:228
    par(i_anl).c_type = "digital";                                          // Spectra.bas:229

    i_anl = i_anl + 1;                                       // Spectra.bas:255
    par(i_anl).c_name = "SigmaZpre";                         // Spectra.bas:256
    par(i_anl).c_title = "Sigma of isobaric Z distribution"; // Spectra.bas:257
    par(i_anl).c_xaxis = "Mass number, pre-neutron";         // Spectra.bas:258
    par(i_anl).c_yaxis = "si^Z$";                            // Spectra.bas:259
    par(i_anl).c_linesymbol = "LRT11";                       // Spectra.bas:260
    par(i_anl).c_type = "digital";                           // Spectra.bas:261

    i_anl = i_anl + 1;                                       // Spectra.bas:264
    par(i_anl).c_name = "SigmaZpost";                        // Spectra.bas:265
    par(i_anl).c_title = "Sigma of isobaric Z distribution"; // Spectra.bas:266
    par(i_anl).c_xaxis = "Mass number, post-neutron";        // Spectra.bas:267
    par(i_anl).c_yaxis = "si^Z$";                            // Spectra.bas:268
    par(i_anl).c_linesymbol = "LRT11";                       // Spectra.bas:269
    par(i_anl).c_type = "digital";                           // Spectra.bas:270

    i_anl = i_anl + 1;                               // Spectra.bas:273
    par(i_anl).c_name = "Zpolarpre";                 // Spectra.bas:274
    par(i_anl).c_title = "Charge polarisation";      // Spectra.bas:275
    par(i_anl).c_xaxis = "Mass number, pre-neutron"; // Spectra.bas:276
    par(i_anl).c_yaxis = "Zb$a$r$ - ZU$C$D$";        // Spectra.bas:277
    par(i_anl).c_linesymbol = "LRT11";               // Spectra.bas:278
    par(i_anl).c_type = "digital";                   // Spectra.bas:279

    i_anl = i_anl + 1;                                       // Spectra.bas:282
    par(i_anl).c_name = "Zpolarmac";                         // Spectra.bas:283
    par(i_anl).c_title = "Charge polarisation, macroscopic"; // Spectra.bas:284
    par(i_anl).c_xaxis = "Mass number, pre-neutron";         // Spectra.bas:285
    par(i_anl).c_yaxis = "Zb$a$r$ - ZU$C$D$";                // Spectra.bas:286
    par(i_anl).c_linesymbol = "LGT11";                       // Spectra.bas:287
    par(i_anl).c_type = "digital";                           // Spectra.bas:288

    i_anl = i_anl + 1;                                // Spectra.bas:291
    par(i_anl).c_name = "Zpolarpost";                 // Spectra.bas:292
    par(i_anl).c_title = "Charge polarisation";       // Spectra.bas:293
    par(i_anl).c_xaxis = "Mass number, post-neutron"; // Spectra.bas:294
    par(i_anl).c_yaxis = "Zb$a$r$ - ZU$C$D$";         // Spectra.bas:295
    par(i_anl).c_linesymbol = "LRT11";                // Spectra.bas:296
    par(i_anl).c_type = "digital";                    // Spectra.bas:297

    i_anl = i_anl + 1;                                                       // Spectra.bas:300
    par(i_anl).c_name = "Edefo2d";                                           // Spectra.bas:301
    par(i_anl).c_title = "Deformation energy over mass number, pre-neutron"; // Spectra.bas:302
    par(i_anl).c_xaxis = "Mass number";                                      // Spectra.bas:303
    par(i_anl).c_yaxis = "Ed$e$f$o$ / MeV";                                  // Spectra.bas:304
    par(i_anl).r_alim(2, 3) = 0x1.99999Ap-4F;                                // Spectra.bas:305
    par(i_anl).i_dim = 2;                                                    // Spectra.bas:306
    par(i_anl).c_type = "digital";                                           // Spectra.bas:307

    i_anl = i_anl + 1;            // Spectra.bas:333
    par(i_anl).c_name = "EdefoA"; // Spectra.bas:334
    par(i_anl).c_title =
        "Mean deformation energy versus mass number, pre-neutron"; // Spectra.bas:335
    par(i_anl).c_xaxis = "Mass number";                            // Spectra.bas:336
    par(i_anl).c_yaxis = "<Ed$e$f$o$> / MeV";                      // Spectra.bas:337
    par(i_anl).r_alim(1, 3) = 0x1.p+0F;                            // Spectra.bas:338
    par(i_anl).c_linesymbol = "LGT11";                             // Spectra.bas:339
    par(i_anl).c_type = "digital";                                 // Spectra.bas:340

    i_anl = i_anl + 1;                                                          // Spectra.bas:344
    par(i_anl).c_name = "JFRAGpre";                                             // Spectra.bas:345
    par(i_anl).c_title = "Fragment spin distribution, unit 1 hb^, pre-neutron"; // Spectra.bas:346
    par(i_anl).c_xaxis = "J / hb^";                                             // Spectra.bas:347
    par(i_anl).c_yaxis = "Counts";                                              // Spectra.bas:348
    par(i_anl).c_linesymbol = "LTR11";                                          // Spectra.bas:349
    par(i_anl).c_type = "digital";                                              // Spectra.bas:350

    i_anl = i_anl + 1;                                                           // Spectra.bas:385
    par(i_anl).c_name = "JFRAGpost";                                             // Spectra.bas:386
    par(i_anl).c_title = "Fragment spin distribution, unit 1 hb^, post-neutron"; // Spectra.bas:387
    par(i_anl).c_xaxis = "J / hb^";                                              // Spectra.bas:388
    par(i_anl).c_yaxis = "Counts";                                               // Spectra.bas:389
    par(i_anl).c_linesymbol = "LTR11";                                           // Spectra.bas:390
    par(i_anl).c_type = "digital";                                               // Spectra.bas:391

    i_anl = i_anl + 1;                                                     // Spectra.bas:426
    par(i_anl).c_name = "Eintr2d";                                         // Spectra.bas:427
    par(i_anl).c_title = "Intrinsic energy over mass number, pre-neutron"; // Spectra.bas:428
    par(i_anl).c_xaxis = "Mass number";                                    // Spectra.bas:429
    par(i_anl).c_yaxis = "Ei$n$t$r$ / MeV";                                // Spectra.bas:430
    par(i_anl).r_alim(2, 3) = 0x1.99999Ap-4F;                              // Spectra.bas:431
    par(i_anl).i_dim = 2;                                                  // Spectra.bas:432
    par(i_anl).c_type = "digital";                                         // Spectra.bas:433

    i_anl = i_anl + 1;                                                            // Spectra.bas:460
    par(i_anl).c_name = "EintrA";                                                 // Spectra.bas:461
    par(i_anl).c_title = "Mean intrinsic energy versus mass number, pre-neutron"; // Spectra.bas:462
    par(i_anl).c_xaxis = "Mass number";                                           // Spectra.bas:463
    par(i_anl).c_yaxis = "<Ei$n$t$r$> / MeV";                                     // Spectra.bas:464
    par(i_anl).c_linesymbol = "LGT11";                                            // Spectra.bas:465
    par(i_anl).c_type = "digital";                                                // Spectra.bas:466

    i_anl = i_anl + 1;                                                      // Spectra.bas:469
    par(i_anl).c_name = "Ecoll2d";                                          // Spectra.bas:470
    par(i_anl).c_title = "Collective energy over mass number, pre-neutron"; // Spectra.bas:471
    par(i_anl).c_xaxis = "Mass number";                                     // Spectra.bas:472
    par(i_anl).c_yaxis = "Ec$o$l$l$ / MeV";                                 // Spectra.bas:473
    par(i_anl).r_alim(2, 3) = 0x1.99999Ap-4F;                               // Spectra.bas:474
    par(i_anl).i_dim = 2;                                                   // Spectra.bas:475
    par(i_anl).c_type = "digital";                                          // Spectra.bas:476

    i_anl = i_anl + 1;            // Spectra.bas:503
    par(i_anl).c_name = "EcollA"; // Spectra.bas:504
    par(i_anl).c_title =
        "Mean collective energy versus mass number, pre-neutron"; // Spectra.bas:505
    par(i_anl).c_xaxis = "Mass number";                           // Spectra.bas:506
    par(i_anl).c_yaxis = "<Ec$o$l$l$> / MeV";                     // Spectra.bas:507
    par(i_anl).r_alim(1, 3) = 0x1.p+0F;                           // Spectra.bas:508
    par(i_anl).c_linesymbol = "LGT11";                            // Spectra.bas:509
    par(i_anl).c_type = "digital";                                // Spectra.bas:510

    i_anl = i_anl + 1;                                                      // Spectra.bas:513
    par(i_anl).c_name = "Eexc2dlight";                                      // Spectra.bas:514
    par(i_anl).c_title = "Excitation energy over mass number, pre-neutron"; // Spectra.bas:515
    par(i_anl).c_xaxis = "Mass number";                                     // Spectra.bas:516
    par(i_anl).c_yaxis = "Ee$x$c$ / MeV";                                   // Spectra.bas:517
    par(i_anl).c_linesymbol = "LTR11";                                      // Spectra.bas:518
    par(i_anl).r_alim(2, 3) = 0x1.99999Ap-4F;                               // Spectra.bas:519
    par(i_anl).i_dim = 2;                                                   // Spectra.bas:520
    par(i_anl).c_type = "digital";                                          // Spectra.bas:521

    i_anl = i_anl + 1;                                                        // Spectra.bas:548
    par(i_anl).c_name = "EexcL2dlight";                                       // Spectra.bas:549
    par(i_anl).c_title = "Intrinsic excitation energy over angular momentum"; // Spectra.bas:550
    par(i_anl).c_xaxis = "L / hb^";                                           // Spectra.bas:551
    par(i_anl).c_yaxis = "Ee$x$c$ / MeV";                                     // Spectra.bas:552
    par(i_anl).r_alim(2, 3) = 0x1.99999Ap-4F;                                 // Spectra.bas:553
    par(i_anl).i_dim = 2;                                                     // Spectra.bas:554
    par(i_anl).c_type = "digital";                                            // Spectra.bas:555

    i_anl = i_anl + 1; // Spectra.bas:558
    // QUIRK(Q-020): the array ErotL2dlight is registered as "ErotL2dheavy"
    par(i_anl).c_name = "ErotL2dheavy";                             // Spectra.bas:559
    par(i_anl).c_title = "Rotational energy over angular momentum"; // Spectra.bas:560
    par(i_anl).c_xaxis = "L / hb^";                                 // Spectra.bas:561
    par(i_anl).c_yaxis = "Er$o$t$ / MeV";                           // Spectra.bas:562
    par(i_anl).r_alim(2, 3) = 0x1.99999Ap-4F;                       // Spectra.bas:563
    par(i_anl).i_dim = 2;                                           // Spectra.bas:564
    par(i_anl).c_type = "digital";                                  // Spectra.bas:565

    i_anl = i_anl + 1;                                                        // Spectra.bas:567
    par(i_anl).c_name = "EexcL2dheavy";                                       // Spectra.bas:568
    par(i_anl).c_title = "Intrinsic excitation energy over angular momentum"; // Spectra.bas:569
    par(i_anl).c_xaxis = "L / hb^";                                           // Spectra.bas:570
    par(i_anl).c_yaxis = "Ee$x$c$ / MeV";                                     // Spectra.bas:571
    par(i_anl).r_alim(2, 3) = 0x1.99999Ap-4F;                                 // Spectra.bas:572
    par(i_anl).i_dim = 2;                                                     // Spectra.bas:573

    i_anl = i_anl + 1; // Spectra.bas:576
    // QUIRK(Q-020): the array ErotL2dheavy is registered as "ErotL2d"
    par(i_anl).c_name = "ErotL2d";                                  // Spectra.bas:577
    par(i_anl).c_title = "Rotational energy over angular momentum"; // Spectra.bas:578
    par(i_anl).c_xaxis = "L / hb^";                                 // Spectra.bas:579
    par(i_anl).c_yaxis = "Er$o$t$ / MeV";                           // Spectra.bas:580
    par(i_anl).r_alim(2, 3) = 0x1.99999Ap-4F;                       // Spectra.bas:581
    par(i_anl).i_dim = 2;                                           // Spectra.bas:582
    par(i_anl).c_type = "digital";                                  // Spectra.bas:583

    i_anl = i_anl + 1;                 // Spectra.bas:586
    par(i_anl).c_name = "Nmulti2dpre"; // Spectra.bas:587
    par(i_anl).c_title =
        "Prompt-neutron multiplicity (from CN) over pre-neutron mass"; // Spectra.bas:588
    par(i_anl).c_xaxis = "Mass number";                                // Spectra.bas:589
    par(i_anl).c_yaxis = "Neutron multiplicity";                       // Spectra.bas:590
    par(i_anl).i_dim = 2;                                              // Spectra.bas:591
    par(i_anl).c_type = "digital";                                     // Spectra.bas:592

    i_anl = i_anl + 1;                  // Spectra.bas:595
    par(i_anl).c_name = "Nmulti2dpost"; // Spectra.bas:596
    par(i_anl).c_title =
        "Prompt-neutron multiplicity (from CN) over post-neutron mass"; // Spectra.bas:597
    par(i_anl).c_xaxis = "Mass number";                                 // Spectra.bas:598
    par(i_anl).c_yaxis = "Neutron multiplicity";                        // Spectra.bas:599
    par(i_anl).i_dim = 2;                                               // Spectra.bas:600
    par(i_anl).c_type = "digital";                                      // Spectra.bas:601

    i_anl = i_anl + 1;            // Spectra.bas:604
    par(i_anl).c_name = "N2dpre"; // Spectra.bas:605
    par(i_anl).c_title =
        "Prompt-neutron multiplicity (from fragments) over pre-neutron mass"; // Spectra.bas:606
    par(i_anl).c_xaxis = "Mass number";                                       // Spectra.bas:607
    par(i_anl).c_yaxis = "Neutron multiplicity";                              // Spectra.bas:608
    par(i_anl).i_dim = 2;                                                     // Spectra.bas:609
    par(i_anl).c_type = "digital";                                            // Spectra.bas:610

    i_anl = i_anl + 1;             // Spectra.bas:613
    par(i_anl).c_name = "N2dpost"; // Spectra.bas:614
    par(i_anl).c_title =
        "Prompt-neutron multiplicity (from fragments) over post-neutron mass"; // Spectra.bas:615
    par(i_anl).c_xaxis = "Mass number";                                        // Spectra.bas:616
    par(i_anl).c_yaxis = "Neutron multiplicity";                               // Spectra.bas:617
    par(i_anl).i_dim = 2;                                                      // Spectra.bas:618
    par(i_anl).c_type = "digital";                                             // Spectra.bas:619

    i_anl = i_anl + 1;                // Spectra.bas:622
    par(i_anl).c_name = "NmultiApre"; // Spectra.bas:623
    par(i_anl).c_title = "Mean prompt neutron multiplicity (from CN) as a function of pre-neutron "
                         "mass";                      // Spectra.bas:624
    par(i_anl).c_xaxis = "Mass number, pre-neutron";  // Spectra.bas:625
    par(i_anl).c_yaxis = "Mean neutron multiplicity"; // Spectra.bas:626
    par(i_anl).c_linesymbol = "LTR11";                // Spectra.bas:627
    par(i_anl).c_type = "digital";                    // Spectra.bas:628

    i_anl = i_anl + 1;                 // Spectra.bas:631
    par(i_anl).c_name = "NmultiApost"; // Spectra.bas:632
    par(i_anl).c_title = "Mean prompt neutron multiplicity (from CN) as a function of post-neutron "
                         "mass";                      // Spectra.bas:633
    par(i_anl).c_xaxis = "Mass number, post-neutron"; // Spectra.bas:634
    par(i_anl).c_yaxis = "Mean neutron multiplicity"; // Spectra.bas:635
    par(i_anl).c_linesymbol = "LTR11";                // Spectra.bas:636
    par(i_anl).c_type = "digital";                    // Spectra.bas:637

    i_anl = i_anl + 1;           // Spectra.bas:640
    par(i_anl).c_name = "NApre"; // Spectra.bas:641
    par(i_anl).c_title = "Mean prompt neutron multiplicity (from fragments) as a function of "
                         "pre-neutron mass";          // Spectra.bas:642
    par(i_anl).c_xaxis = "Mass number, pre-neutron";  // Spectra.bas:643
    par(i_anl).c_yaxis = "Mean neutron multiplicity"; // Spectra.bas:644
    par(i_anl).c_linesymbol = "LTR11";                // Spectra.bas:645
    par(i_anl).c_type = "digital";                    // Spectra.bas:646

    i_anl = i_anl + 1;            // Spectra.bas:649
    par(i_anl).c_name = "NApost"; // Spectra.bas:650
    par(i_anl).c_title = "Mean prompt neutron multiplicity (from fragments) as a function of "
                         "post-neutron mass";         // Spectra.bas:651
    par(i_anl).c_xaxis = "Mass number, post-neutron"; // Spectra.bas:652
    par(i_anl).c_yaxis = "Mean neutron multiplicity"; // Spectra.bas:653
    par(i_anl).c_linesymbol = "LTR11";                // Spectra.bas:654
    par(i_anl).c_type = "digital";                    // Spectra.bas:655

    i_anl = i_anl + 1;                                            // Spectra.bas:658
    par(i_anl).c_name = "EPCN";                                   // Spectra.bas:659
    par(i_anl).c_title = "Prompt proton-energy spectrum from CN"; // Spectra.bas:660
    par(i_anl).c_xaxis = "Energy / MeV";                          // Spectra.bas:661
    par(i_anl).c_yaxis = "Counts";                                // Spectra.bas:662
    par(i_anl).c_linesymbol = "HTR0";                             // Spectra.bas:663
    par(i_anl).c_type = "analog";                                 // Spectra.bas:664
    par(i_anl).r_alim(1, 3) = 0x1.0624DEp-10F;                    // Spectra.bas:665

    i_anl = i_anl + 1;                                             // Spectra.bas:696
    par(i_anl).c_name = "ENCN";                                    // Spectra.bas:697
    par(i_anl).c_title = "Prompt neutron-energy spectrum from CN"; // Spectra.bas:698
    par(i_anl).c_xaxis = "Energy / MeV";                           // Spectra.bas:699
    par(i_anl).c_yaxis = "Counts";                                 // Spectra.bas:700
    par(i_anl).c_linesymbol = "HTRB0";                             // Spectra.bas:701
    par(i_anl).c_type = "analog";                                  // Spectra.bas:702
    par(i_anl).r_alim(1, 3) = 0x1.0624DEp-10F;                     // Spectra.bas:703

    i_anl = i_anl + 1;           // Spectra.bas:725
    par(i_anl).c_name = "ENsci"; // Spectra.bas:726
    par(i_anl).c_title =
        "Prompt neutron-energy spectrum - between saddle and scission"; // Spectra.bas:727
    par(i_anl).c_xaxis = "Energy / MeV";                                // Spectra.bas:728
    par(i_anl).c_yaxis = "Counts";                                      // Spectra.bas:729
    par(i_anl).c_linesymbol = "HTRB0";                                  // Spectra.bas:730
    par(i_anl).c_type = "analog";                                       // Spectra.bas:731
    par(i_anl).r_alim(1, 3) = 0x1.0624DEp-10F;                          // Spectra.bas:732

    i_anl = i_anl + 1;                                             // Spectra.bas:754
    par(i_anl).c_name = "ENCNtest";                                // Spectra.bas:755
    par(i_anl).c_title = "Prompt neutron-energy spectrum from CN"; // Spectra.bas:756
    par(i_anl).c_xaxis = "Energy / MeV";                           // Spectra.bas:757
    par(i_anl).c_yaxis = "Counts";                                 // Spectra.bas:758
    par(i_anl).c_linesymbol = "HTRB0";                             // Spectra.bas:759
    par(i_anl).r_alim(1, 3) = 0x1.99999Ap-4F;                      // Spectra.bas:760

    i_anl = i_anl + 1;                                                    // Spectra.bas:763
    par(i_anl).c_name = "ENfr";                                           // Spectra.bas:764
    par(i_anl).c_title = "Prompt neutron-energy spectrum from fragments"; // Spectra.bas:765
    par(i_anl).c_xaxis = "Energy / MeV";                                  // Spectra.bas:766
    par(i_anl).c_yaxis = "Counts";                                        // Spectra.bas:767
    par(i_anl).c_linesymbol = "HTRG0";                                    // Spectra.bas:768
    par(i_anl).r_alim(1, 3) = 0x1.0624DEp-10F;                            // Spectra.bas:769

    i_anl = i_anl + 1;             // Spectra.bas:791
    par(i_anl).c_name = "ENfrvar"; // Spectra.bas:792
    par(i_anl).c_title =
        "Prompt neutron-energy spectrum from fragments, variable binsize"; // Spectra.bas:793
    par(i_anl).c_xaxis = "Energy / MeV";                                   // Spectra.bas:794
    par(i_anl).c_yaxis = "Counts";                                         // Spectra.bas:795
    par(i_anl).c_linesymbol = "HTRRB0";                                    // Spectra.bas:796

    i_anl = i_anl + 1;            // Spectra.bas:850
    par(i_anl).c_name = "ENfrfs"; // Spectra.bas:851
    par(i_anl).c_title =
        "Prompt neutron-energy spectrum from fragments in fragment frame"; // Spectra.bas:852
    par(i_anl).c_xaxis = "Energy / MeV";                                   // Spectra.bas:853
    par(i_anl).c_yaxis = "Counts";                                         // Spectra.bas:854
    par(i_anl).c_linesymbol = "HTGB0";                                     // Spectra.bas:855
    par(i_anl).r_alim(1, 3) = 0x1.0624DEp-10F;                             // Spectra.bas:856

    i_anl = i_anl + 1;           // Spectra.bas:878
    par(i_anl).c_name = "ENfrC"; // Spectra.bas:879
    par(i_anl).c_title =
        "Prompt neutron-energy spectrum from fragments for Chances (nlost, plost)"; // Spectra.bas:880
    par(i_anl).c_xaxis = "Energy / MeV";       // Spectra.bas:881
    par(i_anl).c_yaxis = "Counts";             // Spectra.bas:882
    par(i_anl).c_linesymbol = "HTGB0";         // Spectra.bas:883
    par(i_anl).r_alim(1, 3) = 0x1.0624DEp-10F; // Spectra.bas:884

    i_anl = i_anl + 1;                                                          // Spectra.bas:915
    par(i_anl).c_name = "ENlight";                                              // Spectra.bas:916
    par(i_anl).c_title = "Prompt neutron-energy spectrum from light fragments"; // Spectra.bas:917
    par(i_anl).c_xaxis = "Energy / MeV";                                        // Spectra.bas:918
    par(i_anl).c_yaxis = "Counts";                                              // Spectra.bas:919
    par(i_anl).c_linesymbol = "HTRB0";                                          // Spectra.bas:920
    par(i_anl).r_alim(1, 3) = 0x1.0624DEp-10F;                                  // Spectra.bas:921

    i_anl = i_anl + 1;                                                          // Spectra.bas:924
    par(i_anl).c_name = "ENheavy";                                              // Spectra.bas:925
    par(i_anl).c_title = "Prompt neutron-energy spectrum from heavy fragments"; // Spectra.bas:926
    par(i_anl).c_xaxis = "Energy / MeV";                                        // Spectra.bas:927
    par(i_anl).c_yaxis = "Counts";                                              // Spectra.bas:928
    par(i_anl).c_linesymbol = "HTBG0";                                          // Spectra.bas:929
    par(i_anl).r_alim(1, 3) = 0x1.0624DEp-10F;                                  // Spectra.bas:930

    i_anl = i_anl + 1;                                         // Spectra.bas:933
    par(i_anl).c_name = "ENM";                                 // Spectra.bas:934
    par(i_anl).c_title = "Neutron-energy spectrum for mode &"; // Spectra.bas:935
    par(i_anl).c_xaxis = "Energy / MeV";                       // Spectra.bas:936
    par(i_anl).c_yaxis = "Counts";                             // Spectra.bas:937
    par(i_anl).c_linesymbol = "HTR0";                          // Spectra.bas:938
    par(i_anl).r_alim(2, 3) = 0x1.0624DEp-10F;                 // Spectra.bas:939

    i_anl = i_anl + 1;              // Spectra.bas:942
    par(i_anl).c_name = "ENApre2d"; // Spectra.bas:943
    par(i_anl).c_title =
        "Neutron-energy spectrum over pre-neutron mass (from fragments)"; // Spectra.bas:944
    par(i_anl).c_xaxis = "Apre";                                          // Spectra.bas:945
    par(i_anl).c_yaxis = "Energy / MeV";                                  // Spectra.bas:946
    par(i_anl).r_alim(2, 3) = 0x1.99999Ap-4F;                             // Spectra.bas:947

    i_anl = i_anl + 1;               // Spectra.bas:950
    par(i_anl).c_name = "ENApost2d"; // Spectra.bas:951
    par(i_anl).c_title =
        "Neutron-energy spectrum over post-neutron mass (from fragments)"; // Spectra.bas:952
    par(i_anl).c_xaxis = "Apost";                                          // Spectra.bas:953
    par(i_anl).c_yaxis = "Energy / MeV";                                   // Spectra.bas:954
    par(i_anl).r_alim(2, 3) = 0x1.99999Ap-4F;                              // Spectra.bas:955

    i_anl = i_anl + 1;            // Spectra.bas:958
    par(i_anl).c_name = "ENApre"; // Spectra.bas:959
    par(i_anl).c_title =
        "Mean neutron energy over pre-neutron mass (from fragments)"; // Spectra.bas:960
    par(i_anl).c_xaxis = "Apre";                                      // Spectra.bas:961
    par(i_anl).c_yaxis = "Energy / MeV";                              // Spectra.bas:962
    par(i_anl).c_linesymbol = "HTR0";                                 // Spectra.bas:963
    par(i_anl).r_alim(2, 3) = 0x1.p+0F;                               // Spectra.bas:964

    i_anl = i_anl + 1;             // Spectra.bas:967
    par(i_anl).c_name = "ENApost"; // Spectra.bas:968
    par(i_anl).c_title =
        "Mean neutron energy over post-neutron mass (from fragments)"; // Spectra.bas:969
    par(i_anl).c_xaxis = "Apost";                                      // Spectra.bas:970
    par(i_anl).c_yaxis = "Energy / MeV";                               // Spectra.bas:971
    par(i_anl).c_linesymbol = "HTB0";                                  // Spectra.bas:972
    par(i_anl).r_alim(2, 3) = 0x1.p+0F;                                // Spectra.bas:973

    i_anl = i_anl + 1;                // Spectra.bas:976
    par(i_anl).c_name = "ENApre2dfs"; // Spectra.bas:977
    par(i_anl).c_title = "Neutron-energy spectrum over pre-neutron mass (from fragments in "
                         "fragment frame)";   // Spectra.bas:978
    par(i_anl).c_xaxis = "Apre";              // Spectra.bas:979
    par(i_anl).c_yaxis = "Energy / MeV";      // Spectra.bas:980
    par(i_anl).r_alim(2, 3) = 0x1.99999Ap-4F; // Spectra.bas:981

    i_anl = i_anl + 1;                 // Spectra.bas:1007
    par(i_anl).c_name = "ENApost2dfs"; // Spectra.bas:1008
    par(i_anl).c_title = "Neutron-energy spectrum over post-neutron mass (from fragments in "
                         "fragment frame)";   // Spectra.bas:1009
    par(i_anl).c_xaxis = "Apost";             // Spectra.bas:1010
    par(i_anl).c_yaxis = "Energy / MeV";      // Spectra.bas:1011
    par(i_anl).r_alim(2, 3) = 0x1.99999Ap-4F; // Spectra.bas:1012

    i_anl = i_anl + 1;              // Spectra.bas:1038
    par(i_anl).c_name = "ENAprefs"; // Spectra.bas:1039
    par(i_anl).c_title = "Mean neutron energy over pre-neutron mass (from fragments in fragment "
                         "frame)";       // Spectra.bas:1040
    par(i_anl).c_xaxis = "Apre";         // Spectra.bas:1041
    par(i_anl).c_yaxis = "Energy / MeV"; // Spectra.bas:1042
    par(i_anl).c_linesymbol = "HTR0";    // Spectra.bas:1043
    par(i_anl).r_alim(2, 3) = 0x1.p+0F;  // Spectra.bas:1044

    i_anl = i_anl + 1;               // Spectra.bas:1047
    par(i_anl).c_name = "ENApostfs"; // Spectra.bas:1048
    par(i_anl).c_title = "Mean neutron energy over post-neutron mass (from fragments in fragment "
                         "frame)";       // Spectra.bas:1049
    par(i_anl).c_xaxis = "Apost";        // Spectra.bas:1050
    par(i_anl).c_yaxis = "Energy / MeV"; // Spectra.bas:1051
    par(i_anl).c_linesymbol = "HTB0";    // Spectra.bas:1052
    par(i_anl).r_alim(2, 3) = 0x1.p+0F;  // Spectra.bas:1053

    i_anl = i_anl + 1;                          // Spectra.bas:1056
    par(i_anl).c_name = "NP";                   // Spectra.bas:1057
    par(i_anl).c_title = "Proton multiplicity"; // Spectra.bas:1058
    par(i_anl).c_xaxis = "Number of protons";   // Spectra.bas:1059
    par(i_anl).c_yaxis = "Probability";         // Spectra.bas:1060
    par(i_anl).c_linesymbol = "LTR11";          // Spectra.bas:1061
    par(i_anl).c_type = "digital";              // Spectra.bas:1062

    i_anl = i_anl + 1;                           // Spectra.bas:1065
    par(i_anl).c_name = "NN";                    // Spectra.bas:1066
    par(i_anl).c_title = "Neutron multiplicity"; // Spectra.bas:1067
    par(i_anl).c_xaxis = "Number of neutrons";   // Spectra.bas:1068
    par(i_anl).c_yaxis = "Probability";          // Spectra.bas:1069
    par(i_anl).c_linesymbol = "LTR11";           // Spectra.bas:1070
    par(i_anl).c_type = "digital";               // Spectra.bas:1071

    i_anl = i_anl + 1;                                     // Spectra.bas:1074
    par(i_anl).c_name = "NNCN";                            // Spectra.bas:1075
    par(i_anl).c_title = "Neutron multiplicity (from CN)"; // Spectra.bas:1076
    par(i_anl).c_xaxis = "Number of neutrons";             // Spectra.bas:1077
    par(i_anl).c_yaxis = "Probability";                    // Spectra.bas:1078
    par(i_anl).c_linesymbol = "LTR11";                     // Spectra.bas:1079
    par(i_anl).c_type = "digital";                         // Spectra.bas:1080
    // QUIRK(Q-020): no `I_Anl = I_Anl + 1` before NNCNtot and NPCNtot; both overwrite NNCN
    par(i_anl).c_name = "NNCNtot";                                     // Spectra.bas:1083
    par(i_anl).c_title = "Neutron multiplicity (from CN) w/o fission"; // Spectra.bas:1084
    par(i_anl).c_xaxis = "Number of neutrons";                         // Spectra.bas:1085
    par(i_anl).c_yaxis = "Probability";                                // Spectra.bas:1086
    par(i_anl).c_linesymbol = "LTRB11";                                // Spectra.bas:1087
    par(i_anl).c_type = "digital";                                     // Spectra.bas:1088
    par(i_anl).c_name = "NPCNtot";                                     // Spectra.bas:1091
    par(i_anl).c_title = "Proton multiplicity (from CN) w/o fission";  // Spectra.bas:1092
    par(i_anl).c_xaxis = "Number of protons";                          // Spectra.bas:1093
    par(i_anl).c_yaxis = "Probability";                                // Spectra.bas:1094
    par(i_anl).c_linesymbol = "LTRB11";                                // Spectra.bas:1095
    par(i_anl).c_type = "digital";                                     // Spectra.bas:1096

    i_anl = i_anl + 1;                                                         // Spectra.bas:1099
    par(i_anl).c_name = "NNsci";                                               // Spectra.bas:1100
    par(i_anl).c_title = "Neutron multiplicity (between saddle and scission)"; // Spectra.bas:1101
    par(i_anl).c_xaxis = "Number of neutrons";                                 // Spectra.bas:1102
    par(i_anl).c_yaxis = "Probability";                                        // Spectra.bas:1103
    par(i_anl).c_linesymbol = "LTRB11";                                        // Spectra.bas:1104
    par(i_anl).c_type = "digital";                                             // Spectra.bas:1105

    i_anl = i_anl + 1;                                            // Spectra.bas:1108
    par(i_anl).c_name = "NNfr";                                   // Spectra.bas:1109
    par(i_anl).c_title = "Neutron multiplicity (from fragments)"; // Spectra.bas:1110
    par(i_anl).c_xaxis = "Number of neutrons";                    // Spectra.bas:1111
    par(i_anl).c_yaxis = "Probability";                           // Spectra.bas:1112
    par(i_anl).c_linesymbol = "LTR11";                            // Spectra.bas:1113
    par(i_anl).c_type = "digital";                                // Spectra.bas:1114

    i_anl = i_anl + 1;                                                  // Spectra.bas:1117
    par(i_anl).c_name = "NNlight";                                      // Spectra.bas:1118
    par(i_anl).c_title = "Neutron multiplicity (from light fragments)"; // Spectra.bas:1119
    par(i_anl).c_xaxis = "Number of neutrons";                          // Spectra.bas:1120
    par(i_anl).c_yaxis = "Probability";                                 // Spectra.bas:1121
    par(i_anl).c_linesymbol = "LTR11";                                  // Spectra.bas:1122
    par(i_anl).c_type = "digital";                                      // Spectra.bas:1123

    i_anl = i_anl + 1;                                                  // Spectra.bas:1126
    par(i_anl).c_name = "NNheavy";                                      // Spectra.bas:1127
    par(i_anl).c_title = "Neutron multiplicity (from heavy fragments)"; // Spectra.bas:1128
    par(i_anl).c_xaxis = "Number of neutrons";                          // Spectra.bas:1129
    par(i_anl).c_yaxis = "Probability";                                 // Spectra.bas:1130
    par(i_anl).c_linesymbol = "LTR11";                                  // Spectra.bas:1131
    par(i_anl).c_type = "digital";                                      // Spectra.bas:1132

    i_anl = i_anl + 1;                                             // Spectra.bas:1135
    par(i_anl).c_name = "Ndirlight";                               // Spectra.bas:1136
    par(i_anl).c_title = "Neutron angle vs. light fragment (cos)"; // Spectra.bas:1137
    par(i_anl).c_xaxis = "cos(alpha)";                             // Spectra.bas:1138
    par(i_anl).c_yaxis = "Counts";                                 // Spectra.bas:1139
    par(i_anl).c_linesymbol = "LTR0";                              // Spectra.bas:1140
    par(i_anl).r_alim(1, 3) = 0x1.47AE14p-7F;                      // Spectra.bas:1141

    i_anl = i_anl + 1;                                                 // Spectra.bas:1144
    par(i_anl).c_name = "nuTKEpre";                                    // Spectra.bas:1145
    par(i_anl).c_title = "Neutron multiplicity vs. TKE (pre-neutron)"; // Spectra.bas:1146
    par(i_anl).c_xaxis = "TKE / MeV";                                  // Spectra.bas:1147
    par(i_anl).c_yaxis = "nu^";                                        // Spectra.bas:1148
    par(i_anl).i_dim = 2;                                              // Spectra.bas:1149
    par(i_anl).c_type = "digital";                                     // Spectra.bas:1150

    i_anl = i_anl + 1;                                                  // Spectra.bas:1153
    par(i_anl).c_name = "nuTKEpost";                                    // Spectra.bas:1154
    par(i_anl).c_title = "Neutron multiplicity vs. TKE (post-neutron)"; // Spectra.bas:1155
    par(i_anl).c_xaxis = "TKE / MeV";                                   // Spectra.bas:1156
    par(i_anl).c_yaxis = "nu^";                                         // Spectra.bas:1157
    par(i_anl).i_dim = 2;                                               // Spectra.bas:1158
    par(i_anl).c_type = "digital";                                      // Spectra.bas:1159

    i_anl = i_anl + 1;                                 // Spectra.bas:1162
    par(i_anl).c_name = "DPLOCAL";                     // Spectra.bas:1163
    par(i_anl).c_title = "Local even-odd effect in Z"; // Spectra.bas:1164
    par(i_anl).c_xaxis = "Z (add 0.5!)";               // Spectra.bas:1165
    par(i_anl).c_yaxis = "de^p$";                      // Spectra.bas:1166
    par(i_anl).c_linesymbol = "LTR11";                 // Spectra.bas:1167
    par(i_anl).c_type = "digital";                     // Spectra.bas:1168

    i_anl = i_anl + 1;                                 // Spectra.bas:1171
    par(i_anl).c_name = "DNLOCAL";                     // Spectra.bas:1172
    par(i_anl).c_title = "Local even-odd effect in N"; // Spectra.bas:1173
    par(i_anl).c_xaxis = "N (add 0.5!)";               // Spectra.bas:1174
    par(i_anl).c_yaxis = "de^n$";                      // Spectra.bas:1175
    par(i_anl).c_linesymbol = "LTB11";                 // Spectra.bas:1176
    par(i_anl).c_type = "digital";                     // Spectra.bas:1177

    i_anl = i_anl + 1;                     // Spectra.bas:1180
    par(i_anl).c_name = "AEkinpre";        // Spectra.bas:1181
    par(i_anl).c_title = "Ekin over Apre"; // Spectra.bas:1182
    par(i_anl).c_xaxis = "Mass number";    // Spectra.bas:1183
    par(i_anl).c_yaxis = "Ek$i$n$ / MeV";  // Spectra.bas:1184
    par(i_anl).i_dim = 2;                  // Spectra.bas:1185

    i_anl = i_anl + 1;                                      // Spectra.bas:1211
    par(i_anl).c_name = "EkinApre";                         // Spectra.bas:1212
    par(i_anl).c_title = "Mean Ekin versus A, pre-neutron"; // Spectra.bas:1213
    par(i_anl).c_xaxis = "Mass number";                     // Spectra.bas:1214
    par(i_anl).c_yaxis = "<Ek$i$n$> / MeV";                 // Spectra.bas:1215

    i_anl = i_anl + 1;                                           // Spectra.bas:1218
    par(i_anl).c_name = "Ekinpre";                               // Spectra.bas:1219
    par(i_anl).c_title = "Fragment kinetic energy, pre-neutron"; // Spectra.bas:1220
    par(i_anl).c_xaxis = "Ek$i$n$ / MeV";                        // Spectra.bas:1221
    par(i_anl).c_yaxis = "Counts";                               // Spectra.bas:1222
    par(i_anl).c_linesymbol = "HTR0";                            // Spectra.bas:1223

    i_anl = i_anl + 1;                                           // Spectra.bas:1226
    par(i_anl).c_name = "EkinpreM";                              // Spectra.bas:1227
    par(i_anl).c_title = "Fragment kinetic energy, pre-neutron"; // Spectra.bas:1228
    par(i_anl).c_xaxis = "Ek$i$n$ / MeV";                        // Spectra.bas:1229
    par(i_anl).c_yaxis = "Counts";                               // Spectra.bas:1230
    par(i_anl).c_linesymbol = "HTRB0";                           // Spectra.bas:1231

    i_anl = i_anl + 1;                      // Spectra.bas:1234
    par(i_anl).c_name = "AEkinpost";        // Spectra.bas:1235
    par(i_anl).c_title = "Ekin over Apost"; // Spectra.bas:1236
    par(i_anl).c_xaxis = "Mass number";     // Spectra.bas:1237
    par(i_anl).c_yaxis = "Ek$i$n$ / MeV";   // Spectra.bas:1238
    par(i_anl).i_dim = 2;                   // Spectra.bas:1239

    i_anl = i_anl + 1;                                       // Spectra.bas:1265
    par(i_anl).c_name = "EkinApost";                         // Spectra.bas:1266
    par(i_anl).c_title = "Mean Ekin versus A, post-neutron"; // Spectra.bas:1267
    par(i_anl).c_xaxis = "Mass number";                      // Spectra.bas:1268
    par(i_anl).c_yaxis = "<Ek$i$n$> / MeV";                  // Spectra.bas:1269

    i_anl = i_anl + 1;                                            // Spectra.bas:1272
    par(i_anl).c_name = "Ekinpost";                               // Spectra.bas:1273
    par(i_anl).c_title = "Fragment kinetic energy, post-neutron"; // Spectra.bas:1274
    par(i_anl).c_xaxis = "Ek$i$n$ / MeV";                         // Spectra.bas:1275
    par(i_anl).c_yaxis = "Counts";                                // Spectra.bas:1276
    par(i_anl).c_linesymbol = "HTB0";                             // Spectra.bas:1277

    i_anl = i_anl + 1;                                            // Spectra.bas:1280
    par(i_anl).c_name = "EkinpostM";                              // Spectra.bas:1281
    par(i_anl).c_title = "Fragment kinetic energy, post-neutron"; // Spectra.bas:1282
    par(i_anl).c_xaxis = "Ek$i$n$ / MeV";                         // Spectra.bas:1283
    par(i_anl).c_yaxis = "Counts";                                // Spectra.bas:1284
    par(i_anl).c_linesymbol = "HTRB0";                            // Spectra.bas:1285

    i_anl = i_anl + 1;                    // Spectra.bas:1288
    par(i_anl).c_name = "ATKEpre";        // Spectra.bas:1289
    par(i_anl).c_title = "TKE over Apre"; // Spectra.bas:1290
    par(i_anl).c_xaxis = "Mass number";   // Spectra.bas:1291
    par(i_anl).c_yaxis = "TKE / MeV";     // Spectra.bas:1292
    par(i_anl).i_dim = 2;                 // Spectra.bas:1293

    i_anl = i_anl + 1;                     // Spectra.bas:1319
    par(i_anl).c_name = "ATKEpost";        // Spectra.bas:1320
    par(i_anl).c_title = "TKE over Apost"; // Spectra.bas:1321
    par(i_anl).c_xaxis = "Mass number";    // Spectra.bas:1322
    par(i_anl).c_yaxis = "TKE / MeV";      // Spectra.bas:1323
    par(i_anl).i_dim = 2;                  // Spectra.bas:1324

    i_anl = i_anl + 1;                      // Spectra.bas:1350
    par(i_anl).c_name = "TKEpre";           // Spectra.bas:1351
    par(i_anl).c_title = "TKE pre-neutron"; // Spectra.bas:1352
    par(i_anl).c_xaxis = "TKE / MeV";       // Spectra.bas:1353
    par(i_anl).c_yaxis = "Counts";          // Spectra.bas:1354
    par(i_anl).c_linesymbol = "HTR0";       // Spectra.bas:1355

    i_anl = i_anl + 1;                                     // Spectra.bas:1358
    par(i_anl).c_name = "TKEApre";                         // Spectra.bas:1359
    par(i_anl).c_title = "Mean TKE versus A, pre-neutron"; // Spectra.bas:1360
    par(i_anl).c_xaxis = "Mass number";                    // Spectra.bas:1361
    par(i_anl).c_yaxis = "<TKE> / MeV";                    // Spectra.bas:1362
    par(i_anl).c_linesymbol = "HTB0";                      // Spectra.bas:1363

    i_anl = i_anl + 1;                      // Spectra.bas:1374
    par(i_anl).c_name = "TKEpreM";          // Spectra.bas:1375
    par(i_anl).c_title = "TKE pre-neutron"; // Spectra.bas:1376
    par(i_anl).c_xaxis = "TKE / MeV";       // Spectra.bas:1377
    par(i_anl).c_yaxis = "Counts";          // Spectra.bas:1378
    par(i_anl).c_linesymbol = "HTBR0";      // Spectra.bas:1379

    i_anl = i_anl + 1;                       // Spectra.bas:1382
    par(i_anl).c_name = "TKEpost";           // Spectra.bas:1383
    par(i_anl).c_title = "TKE post-neutron"; // Spectra.bas:1384
    par(i_anl).c_xaxis = "TKE / MeV";        // Spectra.bas:1385
    par(i_anl).c_yaxis = "Counts";           // Spectra.bas:1386
    par(i_anl).c_linesymbol = "HTR0";        // Spectra.bas:1387

    i_anl = i_anl + 1;                       // Spectra.bas:1390
    par(i_anl).c_name = "TKEpostM";          // Spectra.bas:1391
    par(i_anl).c_title = "TKE post-neutron"; // Spectra.bas:1392
    par(i_anl).c_xaxis = "TKE / MeV";        // Spectra.bas:1393
    par(i_anl).c_yaxis = "Counts";           // Spectra.bas:1394
    par(i_anl).c_linesymbol = "HTBR0";       // Spectra.bas:1395

    i_anl = i_anl + 1;                                      // Spectra.bas:1398
    par(i_anl).c_name = "TKEApost";                         // Spectra.bas:1399
    par(i_anl).c_title = "Mean TKE versus A, post-neutron"; // Spectra.bas:1400
    par(i_anl).c_xaxis = "Mass number";                     // Spectra.bas:1401
    par(i_anl).c_yaxis = "<TKE> / MeV";                     // Spectra.bas:1402
    par(i_anl).c_linesymbol = "HTB0";                       // Spectra.bas:1403

    i_anl = i_anl + 1;                              // Spectra.bas:1414
    par(i_anl).c_name = "TotXE";                    // Spectra.bas:1415
    par(i_anl).c_title = "Total excitation energy"; // Spectra.bas:1416
    par(i_anl).c_xaxis = "TXE / MeV";               // Spectra.bas:1417
    par(i_anl).c_yaxis = "Counts";                  // Spectra.bas:1418
    par(i_anl).c_linesymbol = "HTR0";               // Spectra.bas:1419

    i_anl = i_anl + 1;                           // Spectra.bas:1422
    par(i_anl).c_name = "Qvalues";               // Spectra.bas:1423
    par(i_anl).c_title = "Spectrum of Q values"; // Spectra.bas:1424
    par(i_anl).c_xaxis = "Q value / MeV";        // Spectra.bas:1425
    par(i_anl).c_yaxis = "Counts";               // Spectra.bas:1426
    par(i_anl).c_linesymbol = "HTR0";            // Spectra.bas:1427

    i_anl = i_anl + 1;                           // Spectra.bas:1430
    par(i_anl).c_name = "AQpre";                 // Spectra.bas:1431
    par(i_anl).c_title = "Q value over Ap$r$e$"; // Spectra.bas:1432
    par(i_anl).c_xaxis = "Mass number";          // Spectra.bas:1433
    par(i_anl).c_yaxis = "Q value / MeV";        // Spectra.bas:1434
    par(i_anl).i_dim = 2;                        // Spectra.bas:1435

    i_anl = i_anl + 1;                                  // Spectra.bas:1461
    par(i_anl).c_name = "QA";                           // Spectra.bas:1462
    par(i_anl).c_title = "Mean Q value versus Ap$r$e$"; // Spectra.bas:1463
    par(i_anl).c_xaxis = "Mass number";                 // Spectra.bas:1464
    par(i_anl).c_yaxis = "<Q value> / MeV";             // Spectra.bas:1465
    par(i_anl).c_linesymbol = "HTB0";                   // Spectra.bas:1466

    i_anl = i_anl + 1;                                         // Spectra.bas:1469
    par(i_anl).c_name = "EgammaCN";                            // Spectra.bas:1470
    par(i_anl).c_title = "Prompt-gamma spectrum, pre-fission"; // Spectra.bas:1471
    par(i_anl).c_xaxis = "Ega^$ / MeV";                        // Spectra.bas:1472
    par(i_anl).c_yaxis = "Counts";                             // Spectra.bas:1473
    par(i_anl).c_linesymbol = "HTBR0";                         // Spectra.bas:1474
    par(i_anl).r_alim(1, 3) = 0x1.0624DEp-10F;                 // Spectra.bas:1475

    i_anl = i_anl + 1;                            // Spectra.bas:1497
    par(i_anl).c_name = "Egamma";                 // Spectra.bas:1498
    par(i_anl).c_title = "Prompt-gamma spectrum"; // Spectra.bas:1499
    par(i_anl).c_xaxis = "Ega^$ / MeV";           // Spectra.bas:1500
    par(i_anl).c_yaxis = "Counts";                // Spectra.bas:1501
    par(i_anl).c_linesymbol = "HTBR0";            // Spectra.bas:1502
    par(i_anl).r_alim(1, 3) = 0x1.0624DEp-10F;    // Spectra.bas:1503

    i_anl = i_anl + 1;                                             // Spectra.bas:1563
    par(i_anl).c_name = "EgammaL";                                 // Spectra.bas:1564
    par(i_anl).c_title = "Prompt-gamma spectrum, light fragments"; // Spectra.bas:1565
    par(i_anl).c_xaxis = "Ega^$ / MeV";                            // Spectra.bas:1566
    par(i_anl).c_yaxis = "Counts";                                 // Spectra.bas:1567
    par(i_anl).c_linesymbol = "HTR0";                              // Spectra.bas:1568
    par(i_anl).r_alim(1, 3) = 0x1.0624DEp-10F;                     // Spectra.bas:1569

    i_anl = i_anl + 1;                                             // Spectra.bas:1591
    par(i_anl).c_name = "EgammaH";                                 // Spectra.bas:1592
    par(i_anl).c_title = "Prompt-gamma spectrum, heavy fragments"; // Spectra.bas:1593
    par(i_anl).c_xaxis = "Ega^$ / MeV";                            // Spectra.bas:1594
    par(i_anl).c_yaxis = "Counts";                                 // Spectra.bas:1595
    par(i_anl).c_linesymbol = "HTB0";                              // Spectra.bas:1596
    par(i_anl).r_alim(1, 3) = 0x1.0624DEp-10F;                     // Spectra.bas:1597

    i_anl = i_anl + 1;                                                // Spectra.bas:1619
    par(i_anl).c_name = "EgammaE2";                                   // Spectra.bas:1620
    par(i_anl).c_title = "Prompt-E2-gamma spectrum (from fragments)"; // Spectra.bas:1621
    par(i_anl).c_xaxis = "Ega^$ / MeV";                               // Spectra.bas:1622
    par(i_anl).c_yaxis = "Counts";                                    // Spectra.bas:1623
    par(i_anl).c_linesymbol = "HTG0";                                 // Spectra.bas:1624
    par(i_anl).r_alim(1, 3) = 0x1.0624DEp-10F;                        // Spectra.bas:1625

    i_anl = i_anl + 1;                                                      // Spectra.bas:1647
    par(i_anl).c_name = "NGammatot";                                        // Spectra.bas:1648
    par(i_anl).c_title = "Gamma multiplicity per fission (from fragments)"; // Spectra.bas:1649
    par(i_anl).c_xaxis = "Gamma multiplicity";                              // Spectra.bas:1650
    par(i_anl).c_yaxis = "Counts";                                          // Spectra.bas:1651
    par(i_anl).c_linesymbol = "LTB11";                                      // Spectra.bas:1652
    par(i_anl).c_type = "digital";                                          // Spectra.bas:1653

    i_anl = i_anl + 1;                                        // Spectra.bas:1656
    par(i_anl).c_name = "NgammaA";                            // Spectra.bas:1657
    par(i_anl).c_title = "Gamma multiplicity per fission";    // Spectra.bas:1658
    par(i_anl).c_xaxis = "Post-neutron fragment mass number"; // Spectra.bas:1659
    par(i_anl).c_yaxis = "Gamma multiplicity";                // Spectra.bas:1660
    par(i_anl).i_dim = 2;                                     // Spectra.bas:1661
    par(i_anl).c_type = "digital";                            // Spectra.bas:1662

    i_anl = i_anl + 1;                                     // Spectra.bas:1665
    par(i_anl).c_name = "Egammatot";                       // Spectra.bas:1666
    par(i_anl).c_title = "Total gamma energy per fission"; // Spectra.bas:1667
    par(i_anl).c_xaxis = "Total gamma energy / MeV";       // Spectra.bas:1668
    par(i_anl).c_yaxis = "Counts";                         // Spectra.bas:1669
    par(i_anl).c_linesymbol = "HTBR0";                     // Spectra.bas:1670
    par(i_anl).r_alim(1, 3) = 0x1.0624DEp-10F;             // Spectra.bas:1671

    i_anl = i_anl + 1;                                       // Spectra.bas:1693
    par(i_anl).c_name = "Eentrance";                         // Spectra.bas:1694
    par(i_anl).c_title = "Entrance energy above yrast line"; // Spectra.bas:1695
    par(i_anl).c_xaxis = "Energy after last neutron / MeV";  // Spectra.bas:1696
    par(i_anl).c_yaxis = "Counts";                           // Spectra.bas:1697
    par(i_anl).c_linesymbol = "HTR0";                        // Spectra.bas:1698
    par(i_anl).r_alim(1, 3) = 0x1.0624DEp-10F;               // Spectra.bas:1699

    i_anl = i_anl + 1;                             // Spectra.bas:1722
    par(i_anl).c_name = "Qbeta";                   // Spectra.bas:1723
    par(i_anl).c_title = "Q values of beta decay"; // Spectra.bas:1724
    par(i_anl).c_xaxis = "-Q / MeV";               // Spectra.bas:1725
    par(i_anl).c_yaxis = "Multiplicity";           // Spectra.bas:1726
    par(i_anl).c_linesymbol = "HTG0";              // Spectra.bas:1727
    par(i_anl).r_alim(1, 3) = 0x1.0624DEp-10F;     // Spectra.bas:1728

    i_anl = i_anl + 1;                                                         // Spectra.bas:1734
    par(i_anl).c_name = "d_NZPOST";                                            // Spectra.bas:1735
    par(i_anl).c_title = "Post-neutron fragment distribution (uncertainties)"; // Spectra.bas:1736
    par(i_anl).c_xaxis = "Post-neutron neutron number";                        // Spectra.bas:1737
    par(i_anl).c_yaxis = "Atomic number";                                      // Spectra.bas:1738
    par(i_anl).i_dim = 2;                                                      // Spectra.bas:1739
    par(i_anl).c_type = "digital";                                             // Spectra.bas:1740

    i_anl = i_anl + 1;                // Spectra.bas:1770
    par(i_anl).c_name = "d_ZISOPOST"; // Spectra.bas:1771
    par(i_anl).c_title =
        "Isobaric Z distribution, post-neutron (uncertainties)"; // Spectra.bas:1772
    par(i_anl).c_xaxis = "Z distribution for A = &";             // Spectra.bas:1773
    par(i_anl).c_yaxis = "Counts";                               // Spectra.bas:1774
    par(i_anl).c_linesymbol = "LTR11";                           // Spectra.bas:1775
    par(i_anl).c_type = "digital";                               // Spectra.bas:1776

    i_anl = i_anl + 1;                                                      // Spectra.bas:1804
    par(i_anl).c_name = "d_APOST";                                          // Spectra.bas:1805
    par(i_anl).c_title = "Mass distribution, post neutron (uncertainties)"; // Spectra.bas:1806
    par(i_anl).c_xaxis = "Mass number";                                     // Spectra.bas:1807
    par(i_anl).c_yaxis = "Yield";                                           // Spectra.bas:1808
    par(i_anl).c_linesymbol = "BT11";                                       // Spectra.bas:1809
    par(i_anl).i_dim = 1;                                                   // Spectra.bas:1810
    par(i_anl).c_type = "digital";                                          // Spectra.bas:1811

    i_anl = i_anl + 1;                                                         // Spectra.bas:1814
    par(i_anl).c_name = "d_ZPOST";                                             // Spectra.bas:1815
    par(i_anl).c_title = "Element distribution, post-neutron (uncertainties)"; // Spectra.bas:1816
    par(i_anl).c_xaxis = "Atomic number";                                      // Spectra.bas:1817
    par(i_anl).c_yaxis = "Yield";                                              // Spectra.bas:1818
    par(i_anl).c_linesymbol = "RT11";                                          // Spectra.bas:1819
    par(i_anl).c_type = "digital";                                             // Spectra.bas:1820
    par(i_anl).i_dim = 1;                                                      // Spectra.bas:1821
}

// The DCLbranchingJEFF33.bas section included at GEF.bas:1284 (also for the JEFF-3.1.1
// variant, which uses the JEFF-3.3 branchings, M4.1).
void branching_analyzers(AnalyzerRegistry& reg, std::int64_t& i_anl) {
    auto par = [&reg](std::int64_t i) -> AnalyzerAttributes& { return reg.anl_par(i); };
    i_anl = i_anl + 1;              // DCLbranchingJEFF33.bas:40
    par(i_anl).c_name = "ZISOCUMU"; // DCLbranchingJEFF33.bas:41
    par(i_anl).c_title =
        "Isobaric Z distribution for A = &, cumulative"; // DCLbranchingJEFF33.bas:42
    par(i_anl).c_xaxis = "Atomic number";                // DCLbranchingJEFF33.bas:43
    par(i_anl).c_yaxis = "Yield";                        // DCLbranchingJEFF33.bas:44
    par(i_anl).c_linesymbol = "LRT11";                   // DCLbranchingJEFF33.bas:45
}

} // namespace

AnalyzerRegistry build_analyzer_registry() {
    AnalyzerRegistry reg;
    auto par = [&reg](std::int64_t i) -> AnalyzerAttributes& { return reg.anl_par(i); };
    reg.anl_par.redim({fb::Bounds{0, 1000}}); // GEF.bas:1076 Redim Shared Anl_Par(1000)
    std::int64_t i_anl = 0;                   // GEF.bas:1077

    i_anl = i_anl + 1;                                            // GEF.bas:1087
    par(i_anl).c_name = "Beta";                                   // GEF.bas:1088
    par(i_anl).c_title = "Mean fragment deformation at scission"; // GEF.bas:1089
    par(i_anl).c_xaxis = "Atomic number";                         // GEF.bas:1090
    par(i_anl).c_yaxis = "beta";                                  // GEF.bas:1091
    par(i_anl).c_linesymbol = "LT0";                              // GEF.bas:1092
    par(i_anl).c_type = "digital";                                // GEF.bas:1093
    par(i_anl).r_alim(2, 1) = 0x1.p+0F;                           // GEF.bas:1094

    i_anl = i_anl + 1;                                              // GEF.bas:1099
    par(i_anl).c_name = "Edefo";                                    // GEF.bas:1100
    par(i_anl).c_title = "Fragment deformation energy at scission"; // GEF.bas:1101
    par(i_anl).c_xaxis = "Atomic number";                           // GEF.bas:1102
    par(i_anl).c_yaxis = "E / MeV";                                 // GEF.bas:1103
    par(i_anl).c_linesymbol = "LT0";                                // GEF.bas:1104
    par(i_anl).c_type = "digital";                                  // GEF.bas:1105
    par(i_anl).r_alim(2, 1) = 0x1.p+0F;                             // GEF.bas:1106

    i_anl = i_anl + 1;                         // GEF.bas:1111
    par(i_anl).c_name = "Zmean";               // GEF.bas:1112
    par(i_anl).c_title = "Mean Z at scission"; // GEF.bas:1113
    par(i_anl).c_xaxis = "Mass number";        // GEF.bas:1114
    par(i_anl).c_yaxis = "Zm$e$a$n$";          // GEF.bas:1115
    par(i_anl).c_linesymbol = "LT0";           // GEF.bas:1116
    par(i_anl).c_type = "digital";             // GEF.bas:1117
    par(i_anl).r_alim(2, 1) = 0x1.p+0F;        // GEF.bas:1118

    i_anl = i_anl + 1;                                 // GEF.bas:1123
    par(i_anl).c_name = "Zshift";                      // GEF.bas:1124
    par(i_anl).c_title = "Z polarisation at scission"; // GEF.bas:1125
    par(i_anl).c_xaxis = "Mass number";                // GEF.bas:1126
    par(i_anl).c_yaxis = "Zm$e$a$n$ - ZU$C$D$";        // GEF.bas:1127
    par(i_anl).c_linesymbol = "LT0";                   // GEF.bas:1128
    par(i_anl).c_type = "digital";                     // GEF.bas:1129
    par(i_anl).r_alim(2, 1) = 0x1.p+0F;                // GEF.bas:1130

    i_anl = i_anl + 1;                                                    // GEF.bas:1135
    par(i_anl).c_name = "Temp";                                           // GEF.bas:1136
    par(i_anl).c_title = "Nuclear temperature (level-density parameter)"; // GEF.bas:1137
    par(i_anl).c_xaxis = "Mass number";                                   // GEF.bas:1138
    par(i_anl).c_yaxis = "T / MeV";                                       // GEF.bas:1139
    par(i_anl).c_linesymbol = "LT0";                                      // GEF.bas:1140
    par(i_anl).c_type = "digital";                                        // GEF.bas:1141
    par(i_anl).r_alim(2, 1) = 0x1.p+0F;                                   // GEF.bas:1142

    i_anl = i_anl + 1;                                                          // GEF.bas:1147
    par(i_anl).c_name = "TempFF";                                               // GEF.bas:1148
    par(i_anl).c_title = "Nuclear temperature (level-density parameter) of FF"; // GEF.bas:1149
    par(i_anl).c_xaxis = "Mass number";                                         // GEF.bas:1150
    par(i_anl).c_yaxis = "T / MeV";                                             // GEF.bas:1151
    par(i_anl).c_linesymbol = "LT0";                                            // GEF.bas:1152
    par(i_anl).c_type = "digital";                                              // GEF.bas:1153
    par(i_anl).r_alim(2, 1) = 0x1.p+0F;                                         // GEF.bas:1154

    i_anl = i_anl + 1;                                               // GEF.bas:1159
    par(i_anl).c_name = "Eshell";                                    // GEF.bas:1160
    par(i_anl).c_title = "Local shell effect over pre-neutron mass"; // GEF.bas:1161
    par(i_anl).c_xaxis = "Mass number";                              // GEF.bas:1162
    par(i_anl).c_yaxis = "de^U / MeV";                               // GEF.bas:1163
    par(i_anl).c_linesymbol = "LT0";                                 // GEF.bas:1164
    par(i_anl).c_type = "digital";                                   // GEF.bas:1165
    par(i_anl).r_alim(2, 1) = 0x1.p+0F;                              // GEF.bas:1166

    i_anl = i_anl + 1;                                 // GEF.bas:1171
    par(i_anl).c_name = "PEOZ";                        // GEF.bas:1172
    par(i_anl).c_title = "Local even-odd effect in Z"; // GEF.bas:1173
    par(i_anl).c_xaxis = "Mass number";                // GEF.bas:1174
    par(i_anl).c_yaxis = "de^P";                       // GEF.bas:1175
    par(i_anl).c_linesymbol = "LT0";                   // GEF.bas:1176
    par(i_anl).c_type = "digital";                     // GEF.bas:1177
    par(i_anl).r_alim(2, 1) = 0x1.p+0F;                // GEF.bas:1178

    i_anl = i_anl + 1;                                 // GEF.bas:1183
    par(i_anl).c_name = "PEON";                        // GEF.bas:1184
    par(i_anl).c_title = "Local even-odd effect in N"; // GEF.bas:1185
    par(i_anl).c_xaxis = "Mass number";                // GEF.bas:1186
    par(i_anl).c_yaxis = "de^N";                       // GEF.bas:1187
    par(i_anl).c_linesymbol = "LT0";                   // GEF.bas:1188
    par(i_anl).c_type = "digital";                     // GEF.bas:1189
    par(i_anl).r_alim(2, 1) = 0x1.p+0F;                // GEF.bas:1190

    i_anl = i_anl + 1;                       // GEF.bas:1195
    par(i_anl).c_name = "EPART";             // GEF.bas:1196
    par(i_anl).c_title = "Energy partition"; // GEF.bas:1197
    par(i_anl).c_xaxis = "Mass number";      // GEF.bas:1198
    par(i_anl).c_yaxis =
        "Mean fragment intrinsic excitation energy at scission / MeV"; // GEF.bas:1199
    par(i_anl).c_linesymbol = "LT0";                                   // GEF.bas:1200
    par(i_anl).c_type = "digital";                                     // GEF.bas:1201
    par(i_anl).r_alim(2, 1) = 0x1.p+0F;                                // GEF.bas:1202

    i_anl = i_anl + 1;                            // GEF.bas:1207
    par(i_anl).c_name = "SpinRMSNZ";              // GEF.bas:1208
    par(i_anl).c_title = "RMS spin of fragments"; // GEF.bas:1209
    par(i_anl).c_xaxis = "Neutron number";        // GEF.bas:1210
    par(i_anl).c_yaxis = "Atomic number";         // GEF.bas:1211
    par(i_anl).c_type = "digital";                // GEF.bas:1212
    par(i_anl).i_dim = 2;                         // GEF.bas:1213
    par(i_anl).r_alim(2, 1) = 0x1.p+0F;           // GEF.bas:1214
    par(i_anl).r_alim(3, 1) = 0x1.p+0F;           // GEF.bas:1215
    par(i_anl).r_alim(4, 1) = 0x1.p+0F;           // GEF.bas:1216

    i_anl = i_anl + 1;                             // GEF.bas:1224
    par(i_anl).c_name = "BEldmTF";                 // GEF.bas:1225
    par(i_anl).c_title = "Liquid-drop mass (-BE)"; // GEF.bas:1226
    par(i_anl).c_xaxis = "Neutron number";         // GEF.bas:1227
    par(i_anl).c_yaxis = "Atomic number";          // GEF.bas:1228
    par(i_anl).c_type = "digital";                 // GEF.bas:1229
    par(i_anl).i_dim = 2;                          // GEF.bas:1230

    i_anl = i_anl + 1;                              // GEF.bas:1235
    par(i_anl).c_name = "BEexp";                    // GEF.bas:1236
    par(i_anl).c_title = "Experimental mass (-BE)"; // GEF.bas:1237
    par(i_anl).c_xaxis = "Neutron number";          // GEF.bas:1238
    par(i_anl).c_yaxis = "Atomic number";           // GEF.bas:1239
    par(i_anl).c_type = "digital";                  // GEF.bas:1240
    par(i_anl).i_dim = 2;                           // GEF.bas:1241

    i_anl = i_anl + 1;                                     // GEF.bas:1246
    par(i_anl).c_name = "be^g$s$ (Moeller)";               // GEF.bas:1247
    par(i_anl).c_title = "Nuclear deformations (Moeller)"; // GEF.bas:1248
    par(i_anl).c_xaxis = "Neutron number";                 // GEF.bas:1249
    par(i_anl).c_yaxis = "Atomic number";                  // GEF.bas:1250
    par(i_anl).c_type = "digital";                         // GEF.bas:1251
    par(i_anl).i_dim = 2;                                  // GEF.bas:1252

    i_anl = i_anl + 1;                     // GEF.bas:1257
    par(i_anl).c_name = "ShellMO";         // GEF.bas:1258
    par(i_anl).c_title = "Shell effect";   // GEF.bas:1259
    par(i_anl).c_xaxis = "Neutron number"; // GEF.bas:1260
    par(i_anl).c_yaxis = "Atomic number";  // GEF.bas:1261
    par(i_anl).c_type = "digital";         // GEF.bas:1262
    par(i_anl).i_dim = 2;                  // GEF.bas:1263

    i_anl = i_anl + 1;                                          // GEF.bas:1268
    par(i_anl).c_name = "EVOD";                                 // GEF.bas:1269
    par(i_anl).c_title = "Even-odd fluctuating binding energy"; // GEF.bas:1270
    par(i_anl).c_xaxis = "Neutron number";                      // GEF.bas:1271
    par(i_anl).c_yaxis = "Atomic number";                       // GEF.bas:1272
    par(i_anl).c_type = "digital";                              // GEF.bas:1273
    par(i_anl).i_dim = 2;                                       // GEF.bas:1274

    spectra_bas_analyzers(reg, i_anl); // GEF.bas:1278 #include "Spectra.bas"
    branching_analyzers(reg, i_anl);   // GEF.bas:1284 #include once "DCLbranchingJEFF33.bas"

    i_anl = i_anl + 1;                                        // GEF.bas:1292
    par(i_anl).c_name = "NZPRE";                              // GEF.bas:1293
    par(i_anl).c_title = "Nuclide distribution, pre-neutron"; // GEF.bas:1294
    par(i_anl).c_xaxis = "Neutron number";                    // GEF.bas:1295
    par(i_anl).c_yaxis = "Atomic number";                     // GEF.bas:1296
    par(i_anl).c_type = "digital";                            // GEF.bas:1297
    par(i_anl).i_dim = 2;                                     // GEF.bas:1298

    i_anl = i_anl + 1;                                                 // GEF.bas:1303
    par(i_anl).c_name = "NZMPRE";                                      // GEF.bas:1304
    par(i_anl).c_title = "Nuclide distribution of modes, pre-neutron"; // GEF.bas:1305
    par(i_anl).c_xaxis = "Neutron number";                             // GEF.bas:1306
    par(i_anl).c_yaxis = "Atomic number";                              // GEF.bas:1307
    par(i_anl).c_type = "analog";                                      // GEF.bas:1308
    par(i_anl).i_dim = 2;                                              // GEF.bas:1309

    reg.n_anl = i_anl; // GEF.bas:1311
    return reg;
}

} // namespace gef::analysis
