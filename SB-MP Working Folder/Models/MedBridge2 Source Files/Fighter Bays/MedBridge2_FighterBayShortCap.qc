// Output .MDL
$modelname Spacebuild/MedBridge2_FighterBayShortCap.mdl
$hboxset "default"
// Base or Reference .SMD
$body studio "MedBridge2_FighterBayShortCap_detail.SMD"

// Directory of materials that the model uses
$cdmaterials spacebuild

$keyvalues 
{
 prop_data 
{ 
"base" "Metal.Large"
} 
}

//Model properties
$staticprop
$surfaceprop "metal"
$scale 1.0

// sequences: all sequences are in $cd
$sequence idle "MedBridge2_FighterBayShortCap_detail" loop fps 15

// Physics data
$collisionmodel "MedBridge2_FighterBayShortCap_phys.SMD" {
	$concave
	$mass 100.0
	$inertia 1.00
	$damping 0.00
	$rotdamping 0.00
}
