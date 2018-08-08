// Gmsh .geo script for the galfenol test case.
//
// Modeled: 1/8 of the actual geometry, bottom half.
//
// First we model 1/4 as an axisymmetric slice in 2D, then extrude pi/2 by rotation.
//
// JJ 2017-09-26

// ===================
// geometry parameters
// ===================

make_3d = 1;

debug_vis = 0;  // make visualization easier to debug (low-density mesh)

nslices = 10;

// permanent magnet base
//
r_magnet = 6;
h_magnet = 6;

// magnetostrictive sample
//
r_sample = 3;         // radius
h_sample_neck = 1;    // vertical neck height between base and curved part (set to 0 to disable)
h_sample_total = 24;  // actually total half-height of the sample (including neck), since we model only the bottom half.

circular_taper = 1;  // make the sample tapering circular (1) or linear (0)

// for circular tapering -->

// reference radius for rounding: this gives a perfectly horizontal edge at the end (pi/2 turn).
//
r_rounding_ref = r_magnet - r_sample;

// actual radius of the rounded corner of the sample.
//
// Values smaller than r_rounding_ref will cause the sample to curve back upward at the outer edge of the neck.
//
r_rounding = 1.5*r_rounding_ref;

// <-- for circular tapering

// surrounding air domain
//
r_air_domain = 4 * r_magnet;
h_air_domain_neg = 1.5 * h_sample_total;

// ===================
// meshing parameters
// ===================

// mesh densities
//
m1 = 0.5;  // all inner vertices
m2 = 5.0;  // outer corners of air domain


// ===================
// the script itself
// ===================

If(debug_vis == 1)
  m1 *= 5;
  m2 *= 5;
EndIf


// base (permanent magnet)

p1  = newp; Point(p1)  = {0, 0, 0, m1};
p2  = newp; Point(p2)  = {r_magnet, 0, 0, m1};
p3a = newp; Point(p3a) = {r_magnet, h_magnet, 0, m1};
p4  = newp; Point(p4)  = {0, h_magnet, 0, m1};

l1 = newl; Line(l1) = {p1, p2};
l2 = newl; Line(l2) = {p2, p3a};
l3 = newl; Line(l3) = {p3a, p4};
l4 = newl; Line(l4) = {p4, p1};


// rounded part of sample

y_start = h_magnet + h_sample_neck;

// If a vertical neck exists, we must to create one more point to represent its outer top vertex.
If(h_sample_neck > 0)
  p3b = newp; Point(p3b) = {r_magnet, y_start, 0, m1};
EndIf

// We know that at the center point of the circle, r = r_sample + r_rounding.
//
r_circle_center = r_sample + r_rounding;

// Because we want the circle to touch the inner vertex on the sample vertically, both the circle center point
// and the inner vertex on the sample are located at the same y coordinate.
//
// Use the Pythagorean theorem to solve for this unknown offset.
//
// (Drawing a picture helps here.)
//
r_excess = r_circle_center - r_magnet;
h = Sqrt( r_rounding*r_rounding - r_excess*r_excess );
y_end = y_start + h;

p5 = newp; Point(p5) = {r_sample, y_end, 0, m1};         // inner vertex on the sample
If(circular_taper == 1)
  pc = newp; Point(pc) = {r_circle_center, y_end, 0, m1};  // circle center
EndIf

// top corners of sample

y_top = h_magnet + h_sample_total;

p6 = newp; Point(p6) = {r_sample, y_top, 0, m1};
p7 = newp; Point(p7) = {0, y_top, 0, m1};

// edges of sample

lcirc = newl;
If(h_sample_neck > 0)
  If(circular_taper == 1)
    Circle(lcirc) = {p3b, pc, p5};  // circular taper
  Else
    lcirc = newl; Line(lcirc) = {p3b, p5};  // linear taper
  EndIf
  lneck = newl; Line(lneck) = {p3a, p3b};  // this only appears when there is a neck.
Else
  If(circular_taper == 1)
    Circle(lcirc) = {p3a, pc, p5};  // circular taper
  Else
    lcirc = newl; Line(lcirc) = {p3a, p5};  // linear taper
  EndIf
EndIf

l5 = newl; Line(l5) = {p5, p6};
l6 = newl; Line(l6) = {p6, p7};
l7 = newl; Line(l7) = {p7, p4};


// coil upper corner
//
p8 = newp; Point(p8) = {r_magnet, y_top, 0, m1};

// edges of coil
//
l9 = newl; Line(l9) = {p8, p6};
l8 = newl;
If(h_sample_neck > 0)
  Line(l8) = {p3b, p8};
Else
  Line(l8) = {p3a, p8};
EndIf


// air

y_bot = -h_air_domain_neg;

p9  = newp; Point(p9)  = {r_air_domain, y_top, 0, m2};
p10 = newp; Point(p10) = {r_air_domain, y_bot, 0, m2};
p11 = newp; Point(p11) = {0, y_bot, 0, m2};

l10 = newl; Line(l10) = {p1, p11};
l11 = newl; Line(l11) = {p11, p10};
l12 = newl; Line(l12) = {p10, p9};
l13 = newl; Line(l13) = {p9, p8};


// physical groups for surfaces (axisymmetric 2D)

// permanent magnet

Line Loop(1) = {l1, l2, l3, l4};
Plane Surface(1) = {1};
Physical Surface("magnet_2d") = {1};


// magnetostrictive sample

If(h_sample_neck > 0)
  Line Loop(2) = {l7, -l3, lneck, lcirc, l5, l6};
Else
  Line Loop(2) = {l7, -l3, lcirc, l5, l6};
EndIf
Plane Surface(2) = {2};
Physical Surface("sample_2d") = {2};


// coil

Line Loop(3) = {lcirc, l5, -l9, -l8};
Plane Surface(3) = {3};
Physical Surface("coil_2d") = {3};


// air

If(h_sample_neck > 0)
  Line Loop(4) = {l10, l11, l12, l13, -l8, -lneck, -l2, -l1};
Else
  Line Loop(4) = {l10, l11, l12, l13, -l8, -l2, -l1};
EndIf
Plane Surface(4) = {4};
Physical Surface("air_2d") = {4};


// physical groups for boundaries (axisymmetric 2D)


Physical Line("air_coil_interface_2d") = {l8};
Physical Line("air_magnet_interface_2d") = {l2, l1};
Physical Line("air_tangential_field_boundary_2d") = {l10, l11, l12};
Physical Line("air_upper_edge_2d") = {l13};
If(h_sample_neck > 0)
  Physical Line("air_sample_interface_2d") = {lneck};
EndIf
Physical Line("coil_sample_interface_2d") = {l5, lcirc};
Physical Line("coil_upper_edge_2d") = {l9};
Physical Line("magnet_tangential_field_boundary_2d") = {l4};
Physical Line("sample_magnet_interface_2d") = {l3};
Physical Line("sample_tangential_field_boundary_2d") = {l7};
Physical Line("sample_upper_edge_2d") = {l6};


// now, convert into 3D (extrusion by rotation)

If(make_3d == 1)
  Extrude {{0, 1, 0}, {0, 0, 0}, Pi/2} {
    Surface{2}; Surface{3}; Surface{4}; Surface{1}; Layers{nslices}; Recombine;
  }

  // physical groups for volumes (3D)

  Physical Volume("air_3d") = {3};
  Physical Volume("magnet_3d") = {4};
  Physical Volume("coil_3d") = {2};
  Physical Volume("sample_3d") = {1};

  // TODO: other physical groups for boundaries (3D)

  Physical Surface("air_tangential_field_boundary_3d") = {90, 86, 4, 114};
EndIf

