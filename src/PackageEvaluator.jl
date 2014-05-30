#######################################################################
# PackageEvaluator
# https://github.com/IainNZ/PackageEvaluator.jl
# (c) Iain Dunning 2014
# Licensed under the MIT License
#######################################################################

module PackageEvaluator

include("package.jl")
include("output.jl")
include("onstants.jl")

# evalPkg
# Performs all tests on a single package. Return dict. of test results.
export evalPkg
function evalPkg(pkg::String, addremove=true)
    addremove && Pkg.add(pkg)  # Need to add Pkg first
  
    features = Dict{Symbol,Any}()

    # Get package URL and version from METADATA
    url_path = joinpath(Pkg.dir(),"METADATA",pkg, "url")
    url      = chomp(readall(url_path))
    url      = (url[1:3] == "git")   ? url[7:(end-4)] :
               (url[1:5] == "https") ? url[9:(end-4)] : ""
    features[:URL] = string("http://", url)
    features[:VERSION] = string(Pkg.installed(pkg))

    # Analyze package itself
    pkg_path = Pkg.dir(pkg)
    getInfo(features, pkg_path)             # General info (e.g. commit)
    checkLicense(features, pkg_path)        # Determine license
    checkTesting(features, pkg_path, pkg)   # Actually run packages
    
    addremove && Pkg.rm(pkg)  # Remove Pkg if necessary

    return features
end


# featuresToJSON
# Takes test results and formats them as a JSON string
export featuresToJSON
function featuresToJSON(pkg_name, features)
    keyToJSON(key, value, last=false) = "  \"$key\": \"$value\"$(!last?",":"")\n"
    json_str = "{\n"
    json_str *= keyToJSON("jlver",    string(VERSION.major,".",VERSION.minor))
    json_str *= keyToJSON("name",     pkg_name)
    json_str *= keyToJSON("url",      features[:URL])
    json_str *= keyToJSON("version",  features[:VERSION])
    json_str *= keyToJSON("gitsha",   chomp(features[:GITSHA]))
    json_str *= keyToJSON("gitdate",  chomp(features[:GITDATE]))
    json_str *= keyToJSON("license",  features[:LICENSE])
    json_str *= keyToJSON("licfile",  features[:LICENSE_FILE])
    json_str *= keyToJSON("status",   features[:TEST_STATUS])
    json_str *= keyToJSON("possible", features[:TEST_POSSIBLE] ? "true" : "false", true)
    json_str *= "}"
    return json_str
end

#######################################################################
end #module
