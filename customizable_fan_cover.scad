/*
 * Customizable Fan Cover - https://www.thingiverse.com/thing:2802474
 * by Dennis Hofmann - https://www.thingiverse.com/mightynozzle/about
 * continued improvements by OneHoopyFrood
 * created 2018-02-22
 * updated 2025-04-28
 * version v2.0
 *
 * Changelog
 * --------------
 * v2.0:
 *   - switched to single numeric fan_size parameter
 *   - consolidated preset data into lookup table
 *   - cleaned up variable names and removed typos
 *   - added fallback to custom values for non-standard sizes
 * v1.2:
 *   - improved rounded-corner quality and crosshair pattern
 * v1.1:
 *   - added support‐line option for crosshair and square patterns
 * v1.0:
 *   - final design
 * --------------
 *
 * This work is licensed under the Creative Commons - Attribution - Non-Commercial - ShareAlike license.
 * https://creativecommons.org/licenses/by-nc-sa/3.0/
 */


/* [Global Settings] */
// fan_size: use one of the common presets (25, 30, 40, 50, 60, 70, 80, 92, 120, 140).
// If you choose a size not in the table below, the custom_* values will apply.
fan_size         = 60;

// frame_option: "full" gives a solid border; "reduced" saves material by thinning the frame.
frame_option     = "reduced";

// border_mm: minimum border thickness around the grill; recommended as a multiple of nozzle line width.
border_mm        = 1.92;

// grill_pattern: choose from honeycomb, grid, line, triangle, crosshair, square, dot, aperture.
grill_pattern    = "honeycomb";

// grill_rot: rotation angle for the grill pattern, in degrees.
grill_rot        = 0;

// line_size_mm: thickness of each pattern line, in millimeters.
line_size_mm     = 0.96;

// line_space_mm: spacing between pattern lines, in millimeters.
line_space_mm    = 6;

// screw_chamfer: options for countersinking the screw holes: "no", "top", "bottom", "top_and_bottom".
screw_chamfer    = "no";

// rounded_corners: enable (true) or disable (false) filleted corners on the frame.
rounded_corners  = true;

// support_lines: number of straight support lines for crosshair and square patterns.
support_lines    = 2;


/* [Custom Fan Settings] */
// Only used if fan_size is not found in the presets array.
custom_cover_mm      = 55;
custom_screw_dia_mm  = 4.0;
custom_screw_dist_mm = 45;
custom_cover_h_mm    = 3;
custom_pattern_h_mm  = 1.5;


/* [Internal Calculated Values] */
cover_mm           = 0;
screw_dia_mm       = 0;
screw_hole_dist_mm = 0;
cover_h_mm         = 0;
pattern_h_mm       = 0;


// ------
// Preset Definitions
// ------
presets = [
  [25,  2.9,  20,   2.0, 1.0],
  [30,  3.3,  24,   2.5, 1.1],
  [40,  3.3,  32,   2.7, 1.2],
  [50,  4.4,  40,   2.9, 1.3],
  [60,  4.4,  50,   3.0, 1.3],
  [70,  4.4,  61.5, 3.0, 1.4],
  [80,  4.4,  71.5, 3.2, 1.5],
  [92,  4.4,  82.5, 3.5, 1.6],
  [120, 4.4, 105,  4.0, 1.8],
  [140, 4.4, 126,  4.5, 2.0]
];

// lookup(size) returns [size, dia, dist, h, pattern_h] or [] if not found
function lookup(size) =
    let(matches = [ for(p = presets) if (p[0] == size) p ])
    len(matches) ? matches[0] : [];

// fill in either preset or custom values
_ps = lookup(fan_size);
cover_mm           = len(_ps) ? fan_size            : custom_cover_mm;
screw_dia_mm       = len(_ps) ? _ps[1]              : custom_screw_dia_mm;
screw_hole_dist_mm = len(_ps) ? _ps[2]              : custom_screw_dist_mm;
cover_h_mm         = len(_ps) ? _ps[3]              : custom_cover_h_mm;
pattern_h_mm       = len(_ps) ? _ps[4]              : custom_pattern_h_mm;


// ------
// Derived Geometry
// ------
corner_size = cover_mm - screw_hole_dist_mm;
corner_r    = rounded_corners ? corner_size/2 : 0;
screw_off   = screw_hole_dist_mm/2;


// ------
// Main Call
// ------
fan_cover(
    cover_size           = cover_mm,
    screw_hole_dia       = screw_dia_mm,
    screw_hole_distance  = screw_hole_dist_mm,
    cover_h              = cover_h_mm,
    grill_pattern_height = pattern_h_mm
);


// ------
// Module: fan_cover()
// Builds the rim, grill, and screw holes.
// ------
module fan_cover(cover_size, screw_hole_dia, screw_hole_distance, cover_h, grill_pattern_height) {
    difference() {
        union() {
            // Frame extrusion
            linear_extrude(height = cover_h) difference() {
                offset(r = corner_r, $fn = ceil(corner_r*8))
                    offset(r = -corner_r)
                        square([cover_size, cover_size], center = true);
                if (frame_option == "reduced")
                    offset(r = corner_r) offset(r = -corner_r)
                        square([cover_size-2*border_mm, cover_size-2*border_mm], center = true);
                else
                    circle(d = cover_size-2*border_mm, $fn = cover_size);
            }

            // Corner reliefs for reduced frame
            if (frame_option == "reduced")
                for (y=[-1,1], x=[-1,1])
                    translate([x*screw_off, y*screw_off, -1])
                        circle(d = corner_size, $fn = ceil(corner_r*8));

            // Grill pattern extrusion
            linear_extrude(height = grill_pattern_height) intersection() {
                offset(r = corner_r) offset(r = -corner_r)
                    square([cover_size, cover_size], center = true);
                rotate(grill_rot) {
                    if (grill_pattern == "grid")         grid_pattern(cover_size, line_size_mm, line_space_mm);
                    else if (grill_pattern == "honeycomb") honeycomb_pattern(cover_size, line_size_mm, line_space_mm);
                    else if (grill_pattern == "line")      line_pattern(cover_size, line_size_mm, line_space_mm);
                    else if (grill_pattern == "triangle")  triangle_pattern(cover_size, line_size_mm, line_space_mm);
                    else if (grill_pattern == "crosshair") crosshair_pattern(cover_size, line_size_mm, line_space_mm);
                    else if (grill_pattern == "square")    square_pattern(cover_size, line_size_mm, line_space_mm);
                    else if (grill_pattern == "dot")       dot_pattern(cover_size, line_size_mm, line_space_mm);
                    else if (grill_pattern == "aperture")  aperture_pattern(cover_size, line_size_mm, line_space_mm);
                }
            }
        }

        // Screw holes at four corners
        for (y=[-1,1], x=[-1,1])
            translate([x*screw_off, y*screw_off, -1])
                screw_hole(cover_h + 2, screw_hole_dia);
    }
}


// ------
// Module: screw_hole()
// Creates the through-hole and optional chamfers.
// ------
module screw_hole(cover_h, screw_hole_dia) {
    // main hole
    cylinder(h = cover_h + 4, d = screw_hole_dia, $fn = 16);

    // bottom chamfer
    if (screw_chamfer == "bottom" || screw_chamfer == "top_and_bottom") {
        translate([0,0,2.9 - screw_hole_dia])
            cylinder(h = screw_hole_dia, d1 = screw_hole_dia*4, d2 = screw_hole_dia);
    }
    // top chamfer
    if (screw_chamfer == "top" || screw_chamfer == "top_and_bottom") {
        translate([0,0,cover_h + screw_hole_dia/4])
            cylinder(h = screw_hole_dia, d2 = screw_hole_dia*4, d1 = screw_hole_dia);
    }
}


// ------
// Pattern Modules (unchanged from original) 
// grid_pattern, triangle_pattern, line_pattern, crosshair_pattern,
// square_pattern, honeycomb_pattern, dot_pattern, aperture_pattern
// ------
module grid_pattern(size, line_size, line_space) {
    num = ceil(size / (line_size + line_space) * 1.42);
    for (x = [floor(-num/2) : ceil(num/2)]) {
        translate([x*(line_size+line_space), 0])
            square([line_size, num*(line_size+line_space)], center = true);
        rotate(90)
            translate([x*(line_size+line_space), 0])
                square([line_size, num*(line_size+line_space)], center = true);
    }
}

module triangle_pattern(size, line_size, line_space) {
    num = ceil(size / (line_size + line_space) * 1.42);
    for (x = [floor(-num/2) : ceil(num/2)]) {
        translate([x*(line_size+line_space),0])
            square([line_size, num*(line_size+line_space)], center = true);
        rotate(60)
            translate([x*(line_size+line_space),0])
                square([line_size, num*(line_size+line_space)], center = true);
        rotate(120)
            translate([x*(line_size+line_space),0])
                square([line_size, num*(line_size+line_space)], center = true);
    }
}

module line_pattern(size, line_size, line_space) {
    num = ceil(size / (line_size + line_space) * 1.42);
    for (x = [floor(-num/2) : ceil(num/2)])
        translate([x*(line_size+line_space),0])
            square([line_size, num*(line_size+line_space)], center = true);
}

module crosshair_pattern(size, line_size, line_space) {
    line = (line_size+line_space)*2;
    num  = ceil(size/line *1.42);
    for (n=[1:num])
        difference() {
            circle(d = n*line+line_size*2, $fn = ceil(n*line+line_size*2));
            circle(d = n*line,         $fn = ceil(n*line+line_size*2));
        }
    for (rot=[0 : 90/support_lines*2 : 180])
        rotate(rot+45)
            square([size*2, line_size], center = true);
}

module square_pattern(size, line_size, line_space) {
    line = (line_size+line_space)*2;
    num  = ceil(size/line *1.42);
    for (n=[1:num])
        difference() {
            square([n*line+line_size*2, n*line+line_size*2], center = true);
            square([n*line,             n*line],            center = true);
        }
    for (rot=[0 : 90/support_lines*2 : 180])
        rotate(rot+45)
            square([size*2, line_size], center = true);
}

module honeycomb_pattern(size, line_size, line_space) {
    min_rad  = (line_space/2*sqrt(3))/2 + line_size/2;
    y_offset = sqrt(min_rad*min_rad*4 - min_rad*min_rad);
    num_x    = ceil(size/min_rad/2)*1.42;
    num_y    = ceil(size/y_offset)*1.42;
    difference() {
        square([size*1.42, size*1.42], center = true);
        for (y=[floor(-num_y/2):ceil(num_y/2)]) {
            odd = (y % 2 == 0) ? 0 : min_rad;
            for (x=[floor(-num_x/2):ceil(num_x/2)]) {
                translate([x*min_rad*2 + odd, y*y_offset])
                    rotate(30)
                        circle(d=line_space, $fn=6);
            }
        }
    }
}

module dot_pattern(size, line_size, line_space) {
    rad      = line_space/2;
    y_offset = sqrt((rad+line_size/2)^2*4 - (rad+line_size/2)^2);
    num_x    = ceil(size/rad/2)*1.42;
    num_y    = ceil(size/y_offset)*1.42;
    difference() {
        square([size*1.42, size*1.42], center = true);
        for (y=[floor(-num_y/2):ceil(num_y/2)]) {
            odd = (y % 2 == 0) ? 0 : rad+line_size/2;
            for (x=[floor(-num_x/2):ceil(num_x/2)]) {
                translate([x*(rad+line_size/2)*2 + odd, y*y_offset])
                    circle(d=line_space);
            }
        }
    }
}

module aperture_pattern(size, line_size, line_space) {
    circle(d = line_space, $fn = 8);
    for (rot=[1:2:15]) {
        rotate(360/16*rot)
            translate([line_space/2*cos(360/16) - line_size, -line_size])
                square([line_size, size]);
    }
}
