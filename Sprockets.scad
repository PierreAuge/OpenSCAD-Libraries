// Sprockets
//
// Sprocket construction module by Shawn Steele (c) 2013
// License is MS-PL http://opensource.org/licenses/ms-pl
//
// Used to make sprockets for L3-G0 model, http://L3-G0.blogspot.com,
// Please attribute above if redistributing/modifying.
// 
// http://www.gizmology.net/sprockets.htm has some geometry on sprockets.
//
// Shawn's tables were correct, too correct. I've given 1 thounsandths of an inch or 0.0254mm of tolerance to the sprocket width (thickness) table and the sprockets are now being output with enough play that little or no filing is necessary for the chain to run correctly. They were too tight. - Pierre
//
// Modified by Pierre Auge - 17 March 2017
// 
//
// Usage:
//
// use <sprockets.scad>
// sprocket(size, teeth, bore, hub_diameter, hub_height);
//
//   size:          ANSI Roller Chain Standard Sizes, default 25, or motorcycle sizes,
//                  or 1 for bike w/derailleur or 2 for bike w/o derailleur
//   teeth:         Number of teeth on the sprocket, default 9
//   bore:          Bore diameter, inches (Chain sizes seem to favor inches), default 5/16
//   hub_diameter:  Hub diameter, inches, default 0
//   hub_height:    Hub height TOTAL, default 0.
//
// You may also need to tweak some of the fudge factors, depending on your printer, etc.  See the constants below.

// use <sprockets.scad>
$fn = 180;

sprocket(06B, 8, 0.2 , 0.5, 0.5);
// sprocket(size, teeth, bore, hub_diameter, hub_height);

// Adjust these if it's too tight/loose on your printer
// With the adjustment to the thickness table this seems to work on all of my various printers. I generally fudge the teeth by 1 to 3. - Pierre
FUDGE_BORE=0;	 // mm to fudge the edges of the bore
FUDGE_ROLLER=0; // mm to fudge the hole for the rollers
FUDGE_TEETH=0;  // Additional rounding of the teeth (0 is theoretical,
                // my rep 1 seems to need 1 on medium.)

function inches2mm(inches) = inches * 25.4;
function mm2inches(mm) = mm / 25.4;

module sprocket(size=25, teeth=9, bore=5/16, hub_diameter=0, hub_height=0)
{
	bore_radius_mm = inches2mm(bore)/2;
	hub_radius_mm = inches2mm(hub_diameter)/2;
	hub_height_mm = inches2mm(hub_height);

	difference()
	{
		union()
		{
			sprocket_plate(size, teeth);
			if (hub_diameter != 0 && hub_height != 0)
			cylinder(h=hub_height_mm, r=hub_radius_mm);
		}

		// Make sure the bore goes through everything
		if (bore != 0)
		{
			translate([0,0,-1])
			cylinder(h=2+hub_height_mm+inches2mm(get_thickness(size)), r=bore_radius_mm+FUDGE_BORE);
		}
	}
}

module sprocket_plate(size, teeth)
{
	angle = 360/teeth;
	pitch=inches2mm(get_pitch(size));
	roller=inches2mm(get_roller_diameter(size)/2);
	thickness=inches2mm(get_thickness(size));
	outside_radius = inches2mm(get_pitch(size)*(0.6+1/tan(180/teeth))) / 2;
	pitch_radius = inches2mm(get_pitch(size)/sin(180/teeth)) / 2;

	echo("Pitch=", mm2inches(pitch));
	echo("Pitch mm=", pitch);
	echo("Roller=", mm2inches(roller));
	echo("Roller mm=", roller);
	echo("Thickness=", mm2inches(thickness));
	echo("Thickness mm=", thickness);

	echo("Outside diameter=", mm2inches(outside_radius * 2));
	echo("Outside diameter mm=", outside_radius * 2);
	echo("Pitch Diameter=", mm2inches(pitch_radius * 2));
	echo("Pitch Diameter mm=", pitch_radius * 2);

	middle_radius = sqrt(pow(pitch_radius,2) - pow(pitch/2,2));

	// rotating the fudge is going to put curves in a funny place
	fudge_teeth_x = FUDGE_TEETH * cos(angle/2);
	fudge_teeth_y = FUDGE_TEETH * sin(angle/2);

	difference()
	{
		union()
		{
			// Main plate
//			cylinder(r=pitch_radius-roller+.1, h=thickness);

			intersection()
			{
				// Trim outer points
				translate([0,0,-1])
//				cylinder(r=outside_radius,h=thickness+2);	//logic for shorter teeth
				cylinder(r=pitch_radius-roller+pitch/2, h=thickness+2);

				// Main section
				union()
				{
					// Build the teeth
					for (sprocket=[0:teeth-1])
					{
						// Rotate current sprocket by angle
						rotate([0,0,angle*sprocket])
						intersection()
						{
							translate([-fudge_teeth_x,pitch_radius-fudge_teeth_y,0])
							cylinder(r=pitch-roller-FUDGE_ROLLER-FUDGE_TEETH,h=thickness);
	
							rotate([0,0,angle])
							translate([fudge_teeth_x,pitch_radius-fudge_teeth_y,0])
							cylinder(r=pitch-roller-FUDGE_ROLLER-FUDGE_TEETH,h=thickness);					
						}
					}

					// Make sure to fill the gap in the bottom
					for (sprocket=[0:teeth-1])
					{
						rotate([0,0,angle*sprocket-angle/2])
						translate([-pitch/2,-.01,0])
						cube([pitch,middle_radius+.01,thickness]);
					}
				}
			}
		}

		// Remove holes for the rollers
		for (sprocket=[0:teeth-1])
		{
			rotate([0,0,angle*sprocket])
			translate([0,pitch_radius,-1])
			cylinder(r=roller+FUDGE_ROLLER,h=thickness+2);

// 		I used this for debugging the geometry, it draws guide lines
//			rotate([0,0,angle*sprocket])
//			draw_guides(roller, thickness, pitch, height);
		}
	}

	// guide line for pitch radius
//	cylinder(h=.1,r=outside_radius);
//	cylinder(h=.2,r=pitch_radius);
}

/*
// I used this for debugging the geometry, it draws guide lines
module draw_guides(roller, thickness, pitch, height)
{
	translate([0,-.05,0])
	cube([50,0.1,1]);
	translate([0,pitch-.05,0])
	cube([50,0.1,1]);
	translate([0,-pitch-.05,0])
	cube([50,0.1,1]);
}*/

function get_pitch(size) =
	// ANSI
	size == 25 ? 1/4 :
	size == 35 ? 3/8 :
	size == 40 ? 1/2 :
	size == 41 ? 1/2 :
	size == 50 ? 5/8 :
	size == 60 ? 3/4 :
	size == 80 ? 1 :
    // ANSI BRITISH STANDARD METRIC
    size == 06B ? 3/8 :
	// Bike
	size == 1 ? 1/2 :
	size == 2 ? 1/2 :
	// Motorcycle
	size == 420 ? 1/2 :
	size == 425 ? 1/2 :
	size == 428 ? 1/2 :
	size == 520 ? 5/8 :
	size == 525 ? 5/8 :
	size == 530 ? 5/8 :
	size == 630 ? 3/4 :
	// unknown
	0;

function get_roller_diameter(size) =
	// ANSI
	size == 25 ? .130 :
	size == 35 ? .200 :
	size == 40 ? 5/16 :
	size == 41 ? .306 :
	size == 50 ? .400 :
	size == 60 ? 15/32 :
	size == 80 ? 5/8 :
    // ANSI BRITISH STANDARD METRIC
    size == 06B ? .250 :
	// Bike
	size == 1 ? 5/16 :
	size == 2 ? 5/16 :
	// Motorcycle
	size == 420 ? 5/16 :
	size == 425 ? 5/16 :
	size == 428 ? .335 :
	size == 520 ? .400 :
	size == 525 ? .400 :
	size == 530 ? .400 :
	size == 630 ? 15/32 :
	// unknown
	0;

// I think there's a formula for this, but by the
// time I realized that I already had the table...
function get_thickness(size) =
	// ANSI
	size == 25 ? .109 :
	size == 35 ? .167 :
	size == 40 ? .283 :
	size == 41 ? .226 :
	size == 50 ? .342 :
	size == 60 ? .458 :
	size == 80 ? .574 :
    // ANSI BRITISH STANDARD METRIC
    size == 06B ? .224 :
	// Bike
	size == 1 ? .109 :
	size == 2 ? .083 :
	// Motorcycle
	size == 420 ? .226 :
	size == 425 ? .283 :
	size == 428 ? .283 :
	size == 520 ? .226 :
	size == 525 ? .283 :
	size == 530 ? .342 :
	size == 630 ? .342 :
	// unknown
	0;


