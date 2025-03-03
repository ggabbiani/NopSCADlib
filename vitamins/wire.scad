//
// NopSCADlib Copyright Chris Palmer 2018
// nop.head@gmail.com
// hydraraptor.blogspot.com
//
// This file is part of NopSCADlib.
//
// NopSCADlib is free software: you can redistribute it and/or modify it under the terms of the
// GNU General Public License as published by the Free Software Foundation, either version 3 of
// the License, or (at your option) any later version.
//
// NopSCADlib is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
// without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
// See the GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along with NopSCADlib.
// If not, see <https://www.gnu.org/licenses/>.
//

//
//! Just a BOM entry at the moment and cable bundle size functions for holes, plus cable ties.
//
include <../utils/core/core.scad>
include <zipties.scad>

module wire(colour, strands, length, strand = 0.2)   //! Add stranded wire to the BOM
    vitamin(str(": Wire ", colour, " ", strands, "/", strand, "mm strands, length ",length, "mm"));

module ribbon_cable(ways, length)                   //! Add ribbon cable to the BOM
    vitamin(str(": Ribbon cable ", ways, " way ", length, "mm"));

//
// Cable sizes
//
function cable_wires(cable)     = cable[0]; //! Number of wires in a bundle
function cable_wire_size(cable) = cable[1]; //! Size of each wire in a bundle
function cable_is_ribbon(cable) = len(cable) > 2 && cable[2]; //! Is a ribbon cable?
function cable_wire_colours(cable) = assert(len(cable[3]) == cable_wires(cable)) cable[3]; //! Individual wire colours
function cable(wires, size, colours, ribbon = false) = [wires, size, ribbon, colours]; //! Cable constructor

// numbers from http://mathworld.wolfram.com/CirclePacking.html
function cable_radius(cable) = [0, 1, 2, 2.15, 2.41, 2.7, 3, 3, 3.3][cable_wires(cable)] * cable_wire_size(cable) / 2; //! Radius of a bundle of wires, see <http://mathworld.wolfram.com/CirclePacking.html>.

function wire_hole_radius(cable) = ceil(4 * cable_radius(cable) + 1) / 4; //! Radius of a hole to accept a bundle of wires, rounded up to standard metric drill size

function cable_bundle(cable) = //! Arrangement of a bundle in a flat cable clip
    (cable_is_ribbon(cable) ? [cable_wires(cable), 1] :
    [[0,0], [1,1], [2,1], [2, 1 + sin(60)], [2,2], [3, 1 + sin(60)], [3,2]][cable_wires(cable)]) * cable_wire_size(cable);

function cable_bundle_positions(cable) = let( //! Positions of wires in a bundle to go through a cable strip
        wires = cable_wires(cable),
        bottom = cable_is_ribbon(cable) ? wires : wires < 3 ? wires : ceil(wires / 2),
        top = wires - bottom
    )
    [for(i = [0 : 1 : bottom - 1]) [i - (bottom - 1) / 2, 0.5],
     for(i = [0 : 1 : top - 1])    [i - (top - 1) / 2, top == bottom ? 1.5 : 0.5 + sin(60)]
    ] * cable_wire_size(cable);

function cable_width(cable)  = cable_bundle(cable).x; //! Width in flat clip
function cable_height(cable) = cable_bundle(cable).y; //! Height in flat clip

module mouse_hole(cable, h = 100, teardrop = false) { //! A mouse hole to allow a panel to go over a wire bundle.
    r = wire_hole_radius(cable);

    if(teardrop)
        vertical_tearslot(r = r, l = 2 * r, h = h, plus = true);
    else
        rotate(90)
            slot(r, 2 * r, h = h);
}

module cable_tie_holes(cable_r, h = 100) { //! Holes to thread a ziptie through a panel to make a cable tie.
    r = cnc_bit_r;
    l = 3;
    extrude_if(h)
        for(side = [-1, 1])
            translate([0, side * (cable_r + ziptie_thickness(small_ziptie) / 2)])
                hull()
                    for(end = [-1, 1])
                        translate([end * (l / 2 - r), 0])
                            drill(r, 0);
}

module cable_tie(cable_r, thickness) { //! A ziptie threaded around cable radius `cable_r` and through a panel with specified `thickness`.
    translate_z(cable_r)
        rotate([-90, 0, 90])
            ziptie(small_ziptie, cable_r, thickness);
}
