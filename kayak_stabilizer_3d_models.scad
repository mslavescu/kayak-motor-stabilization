/*
================================================================================
KAYAK MOTOR STABILIZER - COMPLETE 3D MODELS
OpenSCAD Script for 3D Printing Components

Version: 2.0
Date: 2025-09-10
Author: Kilo Code - Enhanced Kayak Stabilization System

This script generates all 3D printable components for the kayak motor
stabilization system including motor mounts, waterproof enclosures,
cable glands, and vibration dampeners.

FEATURES:
- Modular design with separate components
- Waterproofing features (seals, gaskets, drainage)
- Multiple motor type support (servo, stepper, brushless)
- Optimized for FDM printing (Ender 3 compatible)
- Parameterized design for customization
- Comprehensive comments and documentation

USAGE:
1. Set parameters at the top of the script
2. Uncomment the component you want to render
3. Export as STL for 3D printing
4. Use provided slicing settings for best results

================================================================================
*/

// =============================================================================
// CONFIGURATION PARAMETERS
// =============================================================================

// Motor Type Selection
MOTOR_TYPE = "SERVO"; // Options: "SERVO", "NEMA17", "NEMA23", "BRUSHLESS"

// Kayak Hull Parameters
KAYAK_HULL_THICKNESS = 8; // mm - typical fiberglass hull thickness
KAYAK_HULL_RADIUS = 150; // mm - hull curvature radius

// Motor Specifications
SERVO_SIZE = [40, 20, 36.5]; // MG90S dimensions [L, W, H]
NEMA17_SIZE = 42.3; // NEMA 17 face size
NEMA23_SIZE = 56.4; // NEMA 23 face size
BRUSHLESS_DIAMETER = 28; // 2212 motor diameter
BRUSHLESS_LENGTH = 30; // Motor length

// Enclosure Parameters
ENCLOSURE_LENGTH = 120;
ENCLOSURE_WIDTH = 80;
ENCLOSURE_HEIGHT = 50;
WALL_THICKNESS = 3;
LID_THICKNESS = 2;

// Waterproofing Parameters
SEAL_THICKNESS = 2; // O-ring seal thickness
DRAINAGE_HOLE_DIAMETER = 3; // Drainage holes for water egress
GASKET_THICKNESS = 1.5; // Lid gasket thickness

// Mounting Parameters
MOUNT_HOLE_DIAMETER = 5; // M5 mounting holes
CABLE_GLAND_DIAMETER = 12; // Cable gland size
VIBRATION_DAMPENER_HEIGHT = 10;

// Printing Parameters
TOLERANCE = 0.2; // General tolerance for fits
LAYER_HEIGHT = 0.2; // Recommended layer height
INFILL_PERCENTAGE = 30; // Recommended infill

// =============================================================================
// UTILITY MODULES
// =============================================================================

/*
Rounded Rectangle Module
Creates a rectangle with rounded corners for better strength
*/
module rounded_rectangle(length, width, height, radius) {
    hull() {
        translate([radius, radius, 0])
            cylinder(h=height, r=radius, $fn=32);
        translate([length - radius, radius, 0])
            cylinder(h=height, r=radius, $fn=32);
        translate([radius, width - radius, 0])
            cylinder(h=height, r=radius, $fn=32);
        translate([length - radius, width - radius, 0])
            cylinder(h=height, r=radius, $fn=32);
    }
}

/*
Mounting Hole Module
Creates reinforced mounting holes with countersinks
*/
module mounting_hole(diameter, height, countersink_depth = 2) {
    union() {
        // Main hole
        cylinder(h=height, d=diameter, $fn=32);

        // Countersink for screw head
        translate([0, 0, height - countersink_depth])
            cylinder(h=countersink_depth, d1=diameter, d2=diameter * 1.5, $fn=32);

        // Reinforcement around hole
        difference() {
            cylinder(h=height, d=diameter * 2, $fn=32);
            cylinder(h=height, d=diameter * 1.2, $fn=32);
        }
    }
}

/*
Cable Gland Module
Creates waterproof cable entry points
*/
module cable_gland(outer_diameter, inner_diameter, height) {
    difference() {
        // Outer body
        cylinder(h=height, d=outer_diameter, $fn=32);

        // Inner cable hole
        translate([0, 0, WALL_THICKNESS])
            cylinder(h=height, d=inner_diameter, $fn=32);

        // Threaded section for nut
        translate([0, 0, height * 0.7])
            cylinder(h=height * 0.3, d=outer_diameter * 0.8, $fn=6);

        // Seal groove
        translate([0, 0, height * 0.5])
            difference() {
                cylinder(h=SEAL_THICKNESS, d=outer_diameter * 0.9, $fn=32);
                cylinder(h=SEAL_THICKNESS, d=outer_diameter * 0.7, $fn=32);
            }
    }
}

/*
Vibration Dampener Module
Creates flexible mounts to reduce motor vibration
*/
module vibration_dampener(base_diameter, height, flexibility = 0.8) {
    difference() {
        // Main body
        cylinder(h=height, d=base_diameter, $fn=32);

        // Flexible cutouts
        for (i = [0:5]) {
            rotate([0, 0, i * 60])
                translate([base_diameter * flexibility, 0, height * 0.2])
                cylinder(h=height * 0.6, d=base_diameter * 0.3, $fn=16);
        }

        // Center mounting hole
        cylinder(h=height, d=base_diameter * 0.4, $fn=32);
    }
}

// =============================================================================
// MOTOR MOUNT BRACKET MODULE
// =============================================================================

/*
Motor Mount Bracket
Attaches motors to kayak hull with waterproofing features
*/
module motor_mount_bracket() {
    echo("Rendering Motor Mount Bracket for", MOTOR_TYPE);

    // Calculate motor-specific dimensions
    motor_face_size = (MOTOR_TYPE == "SERVO") ? SERVO_SIZE[0] :
                     (MOTOR_TYPE == "NEMA17") ? NEMA17_SIZE :
                     (MOTOR_TYPE == "NEMA23") ? NEMA23_SIZE :
                     BRUSHLESS_DIAMETER;

    motor_height = (MOTOR_TYPE == "SERVO") ? SERVO_SIZE[2] :
                  (MOTOR_TYPE == "BRUSHLESS") ? BRUSHLESS_LENGTH :
                  40; // Default for steppers

    // Main bracket dimensions
    bracket_length = motor_face_size + 40;
    bracket_width = motor_face_size + 20;
    bracket_height = motor_height + 20;

    difference() {
        union() {
            // Main bracket body
            rounded_rectangle(bracket_length, bracket_width, WALL_THICKNESS, 5);

            // Motor mounting face
            translate([bracket_length/2 - motor_face_size/2, bracket_width/2 - motor_face_size/2, WALL_THICKNESS])
                cube([motor_face_size, motor_face_size, 8]);

            // Side reinforcement walls
            translate([0, 0, WALL_THICKNESS])
                cube([WALL_THICKNESS, bracket_width, bracket_height - WALL_THICKNESS]);

            translate([bracket_length - WALL_THICKNESS, 0, WALL_THICKNESS])
                cube([WALL_THICKNESS, bracket_width, bracket_height - WALL_THICKNESS]);

            // Hull attachment points
            translate([10, bracket_width/2 - 15, 0])
                cylinder(h=bracket_height, d=15, $fn=32);

            translate([bracket_length - 10, bracket_width/2 - 15, 0])
                cylinder(h=bracket_height, d=15, $fn=32);
        }

        // Motor mounting holes
        if (MOTOR_TYPE == "SERVO") {
            // Servo horn mounting (simplified)
            translate([bracket_length/2, bracket_width/2, WALL_THICKNESS + 4])
                cylinder(h=5, d=8, $fn=32);
        } else if (MOTOR_TYPE == "NEMA17" || MOTOR_TYPE == "NEMA23") {
            // NEMA mounting pattern
            hole_spacing = (MOTOR_TYPE == "NEMA17") ? 31 : 47.14;
            translate([bracket_length/2 - hole_spacing/2, bracket_width/2 - hole_spacing/2, WALL_THICKNESS])
                cylinder(h=10, d=3.5, $fn=32); // M3 holes

            translate([bracket_length/2 + hole_spacing/2, bracket_width/2 - hole_spacing/2, WALL_THICKNESS])
                cylinder(h=10, d=3.5, $fn=32);

            translate([bracket_length/2 - hole_spacing/2, bracket_width/2 + hole_spacing/2, WALL_THICKNESS])
                cylinder(h=10, d=3.5, $fn=32);

            translate([bracket_length/2 + hole_spacing/2, bracket_width/2 + hole_spacing/2, WALL_THICKNESS])
                cylinder(h=10, d=3.5, $fn=32);
        } else if (MOTOR_TYPE == "BRUSHLESS") {
            // Brushless motor mounting (3 holes)
            for (i = [0:2]) {
                rotate([0, 0, i * 120])
                    translate([motor_face_size/2 * 0.7, 0, WALL_THICKNESS])
                    cylinder(h=10, d=3.5, $fn=32);
            }
        }

        // Hull mounting holes
        translate([10, bracket_width/2, WALL_THICKNESS])
            mounting_hole(MOUNT_HOLE_DIAMETER, bracket_height);

        translate([bracket_length - 10, bracket_width/2, WALL_THICKNESS])
            mounting_hole(MOUNT_HOLE_DIAMETER, bracket_height);

        // Drainage holes for waterproofing
        translate([bracket_length/4, bracket_width/4, 0])
            cylinder(h=WALL_THICKNESS, d=DRAINAGE_HOLE_DIAMETER, $fn=16);

        translate([3*bracket_length/4, 3*bracket_width/4, 0])
            cylinder(h=WALL_THICKNESS, d=DRAINAGE_HOLE_DIAMETER, $fn=16);

        // Cable routing channels
        translate([bracket_length/2, bracket_width - 10, WALL_THICKNESS])
            cube([15, 10, bracket_height - WALL_THICKNESS]);
    }

    // Add vibration dampeners
    translate([10, bracket_width/2, bracket_height])
        vibration_dampener(12, VIBRATION_DAMPENER_HEIGHT);

    translate([bracket_length - 10, bracket_width/2, bracket_height])
        vibration_dampener(12, VIBRATION_DAMPENER_HEIGHT);
}

// =============================================================================
// ENCLOSURE HOUSING MODULE
// =============================================================================

/*
Waterproof Electronics Enclosure
Houses ESP32, IMU, and motor controllers
*/
module enclosure_housing() {
    echo("Rendering Waterproof Electronics Enclosure");

    difference() {
        union() {
            // Main enclosure body
            rounded_rectangle(ENCLOSURE_LENGTH, ENCLOSURE_WIDTH, ENCLOSURE_HEIGHT, 8);

            // Lid mounting flanges
            translate([0, 0, ENCLOSURE_HEIGHT - 5])
                difference() {
                    rounded_rectangle(ENCLOSURE_LENGTH, ENCLOSURE_WIDTH, 5, 8);
                    translate([WALL_THICKNESS, WALL_THICKNESS, 0])
                        rounded_rectangle(ENCLOSURE_LENGTH - 2*WALL_THICKNESS,
                                       ENCLOSURE_WIDTH - 2*WALL_THICKNESS, 5, 6);
                }

            // External mounting points
            translate([10, ENCLOSURE_WIDTH/2 - 10, 0])
                cylinder(h=ENCLOSURE_HEIGHT + 10, d=20, $fn=32);

            translate([ENCLOSURE_LENGTH - 10, ENCLOSURE_WIDTH/2 - 10, 0])
                cylinder(h=ENCLOSURE_HEIGHT + 10, d=20, $fn=32);
        }

        // Internal cavity
        translate([WALL_THICKNESS, WALL_THICKNESS, WALL_THICKNESS])
            rounded_rectangle(ENCLOSURE_LENGTH - 2*WALL_THICKNESS,
                           ENCLOSURE_WIDTH - 2*WALL_THICKNESS,
                           ENCLOSURE_HEIGHT - WALL_THICKNESS, 6);

        // Lid mounting holes
        lid_hole_positions = [
            [15, 15, ENCLOSURE_HEIGHT - 5],
            [ENCLOSURE_LENGTH - 15, 15, ENCLOSURE_HEIGHT - 5],
            [15, ENCLOSURE_WIDTH - 15, ENCLOSURE_HEIGHT - 5],
            [ENCLOSURE_LENGTH - 15, ENCLOSURE_WIDTH - 15, ENCLOSURE_HEIGHT - 5]
        ];

        for (pos = lid_hole_positions) {
            translate(pos)
                cylinder(h=5, d=3.5, $fn=32); // M3 holes
        }

        // Cable gland holes
        translate([ENCLOSURE_LENGTH/4, 0, ENCLOSURE_HEIGHT/2])
            rotate([-90, 0, 0])
            cylinder(h=WALL_THICKNESS, d=CABLE_GLAND_DIAMETER, $fn=32);

        translate([3*ENCLOSURE_LENGTH/4, 0, ENCLOSURE_HEIGHT/2])
            rotate([-90, 0, 0])
            cylinder(h=WALL_THICKNESS, d=CABLE_GLAND_DIAMETER, $fn=32);

        // Waterproof button hole
        translate([ENCLOSURE_LENGTH/2, ENCLOSURE_WIDTH - WALL_THICKNESS, ENCLOSURE_HEIGHT/2])
            cylinder(h=WALL_THICKNESS, d=20, $fn=32);

        // Drainage holes (bottom)
        translate([ENCLOSURE_LENGTH/3, WALL_THICKNESS, 0])
            cylinder(h=WALL_THICKNESS, d=DRAINAGE_HOLE_DIAMETER, $fn=16);

        translate([2*ENCLOSURE_LENGTH/3, WALL_THICKNESS, 0])
            cylinder(h=WALL_THICKNESS, d=DRAINAGE_HOLE_DIAMETER, $fn=16);

        // External mounting holes
        translate([10, ENCLOSURE_WIDTH/2, WALL_THICKNESS])
            mounting_hole(MOUNT_HOLE_DIAMETER, ENCLOSURE_HEIGHT);

        translate([ENCLOSURE_LENGTH - 10, ENCLOSURE_WIDTH/2, WALL_THICKNESS])
            mounting_hole(MOUNT_HOLE_DIAMETER, ENCLOSURE_HEIGHT);
    }

    // Internal mounting pillars for PCB
    pillar_positions = [
        [20, 20, WALL_THICKNESS],
        [ENCLOSURE_LENGTH - 20, 20, WALL_THICKNESS],
        [20, ENCLOSURE_WIDTH - 20, WALL_THICKNESS],
        [ENCLOSURE_LENGTH - 20, ENCLOSURE_WIDTH - 20, WALL_THICKNESS]
    ];

    for (pos = pillar_positions) {
        translate(pos)
            difference() {
                cylinder(h=ENCLOSURE_HEIGHT - WALL_THICKNESS - 5, d=8, $fn=32);
                translate([0, 0, ENCLOSURE_HEIGHT - WALL_THICKNESS - 10])
                    cylinder(h=5, d=3.5, $fn=32); // M3 holes
            }
    }
}

// =============================================================================
// ENCLOSURE LID MODULE
// =============================================================================

/*
Enclosure Lid with Waterproof Seal
Creates watertight seal with integrated gasket
*/
module enclosure_lid() {
    echo("Rendering Waterproof Enclosure Lid");

    difference() {
        union() {
            // Main lid body
            rounded_rectangle(ENCLOSURE_LENGTH, ENCLOSURE_WIDTH, LID_THICKNESS, 8);

            // Gasket channel
            translate([WALL_THICKNESS/2, WALL_THICKNESS/2, LID_THICKNESS])
                difference() {
                    rounded_rectangle(ENCLOSURE_LENGTH - WALL_THICKNESS,
                                   ENCLOSURE_WIDTH - WALL_THICKNESS,
                                   GASKET_THICKNESS, 7);
                    translate([1, 1, 0])
                        rounded_rectangle(ENCLOSURE_LENGTH - WALL_THICKNESS - 2,
                                       ENCLOSURE_WIDTH - WALL_THICKNESS - 2,
                                       GASKET_THICKNESS, 6);
                }
        }

        // Lid mounting holes
        lid_hole_positions = [
            [15, 15, 0],
            [ENCLOSURE_LENGTH - 15, 15, 0],
            [15, ENCLOSURE_WIDTH - 15, 0],
            [ENCLOSURE_LENGTH - 15, ENCLOSURE_WIDTH - 15, 0]
        ];

        for (pos = lid_hole_positions) {
            translate(pos)
                cylinder(h=LID_THICKNESS + GASKET_THICKNESS, d=3.5, $fn=32);
        }

        // Ventilation slots (covered by membrane)
        translate([ENCLOSURE_LENGTH/2 - 20, ENCLOSURE_WIDTH/2 - 5, 0])
            cube([40, 10, LID_THICKNESS]);
    }

    // Lid handle
    translate([ENCLOSURE_LENGTH/2 - 15, ENCLOSURE_WIDTH/2 - 5, LID_THICKNESS])
        difference() {
            rounded_rectangle(30, 10, 3, 2);
            translate([5, 2.5, 0])
                cylinder(h=3, d=3, $fn=32);
            translate([25, 2.5, 0])
                cylinder(h=3, d=3, $fn=32);
        }
}

// =============================================================================
// CABLE GLAND MODULE
// =============================================================================

/*
Cable Gland Assembly
Provides waterproof cable entry points
*/
module cable_gland_assembly() {
    echo("Rendering Cable Gland Assembly");

    gland_outer = CABLE_GLAND_DIAMETER;
    gland_inner = 6; // Cable diameter
    gland_length = 25;

    // Main gland body
    difference() {
        union() {
            // Threaded section
            cylinder(h=gland_length * 0.6, d=gland_outer, $fn=6);

            // Compression section
            translate([0, 0, gland_length * 0.6])
                cylinder(h=gland_length * 0.4, d=gland_outer * 0.9, $fn=32);
        }

        // Cable hole
        cylinder(h=gland_length, d=gland_inner, $fn=32);

        // Compression slots
        for (i = [0:3]) {
            rotate([0, 0, i * 90])
                translate([gland_outer * 0.6, 0, gland_length * 0.7])
                cube([2, gland_outer, gland_length * 0.3]);
        }
    }

    // Locking nut
    translate([gland_outer + 10, 0, 0])
        difference() {
            cylinder(h=5, d=gland_outer * 1.2, $fn=6);
            cylinder(h=5, d=gland_outer, $fn=6);
        }

    // Sealing washer
    translate([gland_outer + 10, gland_outer + 10, 0])
        difference() {
            cylinder(h=2, d=gland_outer * 1.1, $fn=32);
            cylinder(h=2, d=gland_outer * 0.9, $fn=32);
        }
}

// =============================================================================
// VIBRATION DAMPENER MODULE
// =============================================================================

/*
Advanced Vibration Dampener
Flexible mounting system to reduce motor vibration transmission
*/
module advanced_vibration_dampener() {
    echo("Rendering Advanced Vibration Dampener");

    base_diameter = 30;
    top_diameter = 20;
    height = VIBRATION_DAMPENER_HEIGHT;

    difference() {
        union() {
            // Base mounting plate
            cylinder(h=3, d=base_diameter, $fn=32);

            // Flexible middle section
            translate([0, 0, 3])
                cylinder(h=height - 6, d1=base_diameter, d2=top_diameter, $fn=32);

            // Top mounting plate
            translate([0, 0, height - 3])
                cylinder(h=3, d=top_diameter, $fn=32);
        }

        // Base mounting holes
        for (i = [0:2]) {
            rotate([0, 0, i * 120])
                translate([base_diameter * 0.6, 0, 0])
                cylinder(h=3, d=4, $fn=32);
        }

        // Top mounting hole
        translate([0, 0, height - 3])
            cylinder(h=3, d=8, $fn=32);

        // Flexibility cuts
        for (i = [0:5]) {
            rotate([0, 0, i * 60])
                translate([base_diameter * 0.7, 0, 3])
                cube([base_diameter * 0.3, 2, height - 6]);
        }
    }
}

// =============================================================================
// ASSEMBLY AND RENDERING
// =============================================================================

/*
Main Assembly Module
Combines all components into complete system
*/
module complete_assembly() {
    echo("Rendering Complete Kayak Stabilizer Assembly");

    // Left motor mount
    translate([-ENCLOSURE_LENGTH/2 - 50, 0, 0])
        motor_mount_bracket();

    // Right motor mount
    translate([ENCLOSURE_LENGTH/2 + 50, 0, 0])
        motor_mount_bracket();

    // Electronics enclosure
    enclosure_housing();

    // Enclosure lid (slightly offset for visibility)
    translate([0, 0, ENCLOSURE_HEIGHT + 5])
        enclosure_lid();

    // Cable glands
    translate([ENCLOSURE_LENGTH/4, ENCLOSURE_WIDTH/2, ENCLOSURE_HEIGHT/2])
        rotate([90, 0, 0])
        cable_gland_assembly();

    // Vibration dampeners
    translate([-ENCLOSURE_LENGTH/2 - 50, 0, 50])
        advanced_vibration_dampener();

    translate([ENCLOSURE_LENGTH/2 + 50, 0, 50])
        advanced_vibration_dampener();
}

// =============================================================================
// RENDERING OPTIONS
// =============================================================================

// Uncomment the component you want to render:

// Individual Components
// motor_mount_bracket();        // Motor mounting bracket
// enclosure_housing();          // Waterproof electronics enclosure
// enclosure_lid();              // Enclosure lid with gasket
// cable_gland_assembly();       // Cable gland with accessories
// advanced_vibration_dampener(); // Vibration dampening mount

// Complete Assembly
complete_assembly();            // Full system assembly

// =============================================================================
// EXPORT INSTRUCTIONS
// =============================================================================

/*
To export individual components:

1. Comment out all other module calls
2. Uncomment only the desired component
3. Use OpenSCAD's "Export as STL" feature
4. Save with descriptive filename

Example filenames:
- motor_mount_bracket.stl
- enclosure_housing.stl
- enclosure_lid.stl
- cable_gland.stl
- vibration_dampener.stl

For 3D printing:
- Use the settings provided in 3d_printing_models.md
- Print with ABS for marine applications
- Use brim for bed adhesion
- Allow parts to cool completely before removal
*/

// =============================================================================
// CUSTOMIZATION EXAMPLES
// =============================================================================

/*
Example: Large kayak with NEMA 23 motors
Modify parameters at the top:
MOTOR_TYPE = "NEMA23";
KAYAK_HULL_THICKNESS = 12;
ENCLOSURE_LENGTH = 150;
ENCLOSURE_WIDTH = 100;
ENCLOSURE_HEIGHT = 60;
*/

/*
Example: Small kayak with servo motors
MOTOR_TYPE = "SERVO";
KAYAK_HULL_THICKNESS = 6;
ENCLOSURE_LENGTH = 100;
ENCLOSURE_WIDTH = 70;
ENCLOSURE_HEIGHT = 40;
*/

// =============================================================================
// MATERIAL AND PRINTING NOTES
// =============================================================================

/*
MATERIAL RECOMMENDATIONS:

ABS (Recommended for marine use):
- Temperature: 240°C nozzle, 100°C bed
- Strength: Excellent impact resistance
- Waterproof: Good with proper sealing
- Flexibility: Medium

PLA (Alternative for non-marine):
- Temperature: 200°C nozzle, 60°C bed
- Strength: Good
- Waterproof: Poor (absorbs water)
- Flexibility: Low

PRINTING OPTIMIZATIONS:
- Wall thickness: 3 layers minimum
- Infill: 30% for strength, 100% for waterproof
- Supports: Generate for overhangs >60°
- Brim: 5mm for bed adhesion
- Cooling: 50% fan speed after layer 2

POST-PROCESSING:
- Sand rough surfaces
- Apply waterproof coating if needed
- Test fit with actual components
- Verify waterproof integrity
*/

// =============================================================================
// END OF SCRIPT
// =============================================================================