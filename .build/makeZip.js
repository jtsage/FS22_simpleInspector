/*
------------------------------------------------------
---- FS22 Mod ZIP Builder ----------------------------
------------------------------------------------------
---- You'll need "glob" and "adm-zip" installed ------
---- globally.  Set the zip name below, source  ------
---- assumed to be in ./src                     ------
------------------------------------------------------
*/

const zipName = "FS22_SimpleInspector"

const glob   = require("glob")
const path   = require('path');
const AdmZip = require("adm-zip");
const fs     = require('fs')

const filesToAdd = glob.sync("../src/**", {nodir: true})
const zipPath    = "../" + zipName + ".zip"

console.log("Refreshing ZIP File...")

var zip = new AdmZip();

filesToAdd.forEach((file) => {
	const relPath   = path.relative("../src/", file)
	const zipFolder = path.dirname(relPath)

	zip.addLocalFile(file, ( zipFolder == "." ? null : zipFolder ) );

	console.log("  Adding:" + path.relative("../src/", file))
})

if ( fs.existsSync(zipPath)) {
	console.log("  Removing Stale ZIP file")
	fs.rmSync(zipPath)
}

console.log("  Writing New ZIP File")
zip.writeZip("../" + zipName + ".zip")
console.log("Done.")