# MATLABTestDataProcessingTools
Various MATLAB scripts and functions used to import and process data obtained during my thesis project.

Step1_fileImport.m To-Do
- Remove dependency on eval by importing everything regardless.
- save three files: [raw] which will be raw data, [filtered] which will be what is filtered, and [lean] which I will later use to help reduce memory usuage
- tweak file storage

Step3_DataProcessing.m To-Do
- Create function that accounts for rotation normal to vertical wirepots measuring twist
- Clean up COR function. Use horizontal wirepots and average displacement. Also include strain gauges though they are innacurate.
- Include strain-bolt in force calculations.
- Possibly consider changing order of strain gauges in variables. Have first 4 be column strain gauges, fifth be bolt strain gauge, and last 4-5 be the shear tab. This will allow us to check only length and know what shear tab we are on and how to handle multiple SGs.
- Include dimensions of larger strain gauges. Go to lab and get info.
