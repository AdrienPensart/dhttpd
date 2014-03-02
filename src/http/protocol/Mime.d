module http.protocol.Mime;

unittest
{
	auto mimes = new MimeMap();
	string filename = "home.html";
	assert(mimes.match(filename) == "text/html");
}

class MimeMap
{
	string[string] mimes;

	string match(string filename, string defaultMime="")
	{
		foreach(ext, mime; mimes)
		{
			if(filename.length > ext.length && filename[$-ext.length..$] == ext)
			{
				return mime;
			}
		}
		return defaultMime;
	}

	this()
	{
		mimes = [
        ".obd" : "application/x-msbinder",
        ".obj" : "application/octet-stream",
        ".silo" : "model/mesh",
        ".pml" : "application/vnd.ctc-posml",
        ".gam" : "chemical/x-gamess-input",
        ".iso" : "application/x-iso9660-image",
        ".rl" : "application/resource-lists+xml",
        ".ras" : "image/x-cmu-raster",
        ".rar" : "application/rar",
        ".embl" : "chemical/x-embl-dl-nucleotide",
        ".mrc" : "application/marc",
        ".sdkd" : "application/vnd.solent.sdkm+xml",
        ".bcpio" : "application/x-bcpio",
        ".sdkm" : "application/vnd.solent.sdkm+xml",
        ".list3820" : "application/vnd.ibm.modcap",
        ".ecelp7470" : "audio/vnd.nuera.ecelp7470",
        ".ist" : "chemical/x-isostar",
        ".bz" : "application/x-bzip",
        ".bmp" : "image/x-ms-bmp",
        ".gen" : "chemical/x-genbank",
        ".jisp" : "application/vnd.jisp",
        ".bmi" : "application/vnd.bmi",
        ".tcl" : "text/x-tcl",
        ".dvi" : "application/x-dvi",
        ".aif" : "audio/x-aiff",
        ".rd" : "chemical/x-mdl-rdfile",
        ".gjf" : "chemical/x-gaussian-input",
        ".hpid" : "application/vnd.hp-hpid",
        ".ott" : "application/vnd.oasis.opendocument.text-template",
        ".rss" : "application/rss+xml",
        ".ots" : "application/vnd.oasis.opendocument.spreadsheet-template",
        ".cst" : "application/vnd.commonspace",
        ".p10" : "application/pkcs10",
        ".csv" : "text/comma-separated-values",
        ".p12" : "application/x-pkcs12",
        ".csp" : "application/vnd.commonspace",
        ".sus" : "application/vnd.sus-calendar",
        ".css" : "text/css",
        ".csm" : "chemical/x-csml",
        ".otg" : "application/vnd.oasis.opendocument.graphics-template",
        ".otf" : "application/vnd.oasis.opendocument.formula-template",
        ".csh" : "text/x-csh",
        ".otc" : "application/vnd.oasis.opendocument.chart-template",
        ".otm" : "application/vnd.oasis.opendocument.text-master",
        ".csf" : "chemical/x-cache-csf",
        ".clkp" : "application/vnd.crick.clicker.palette",
        ".pdf" : "application/pdf",
        ".bdm" : "application/vnd.syncml.dm+wbxml",
        ".pm" : "text/x-perl",
        ".pl" : "text/x-perl",
        ".atomsvc" : "application/atomsvc+xml",
        ".pk" : "application/x-tex-pk",
        ".chm" : "chemical/x-chemdraw",
        ".djv" : "image/vnd.djvu",
        ".hta" : "application/hta",
        ".py" : "text/x-python",
        ".mopcrt" : "chemical/x-mopac-input",
        ".xml" : "application/xml",
        ".umj" : "application/vnd.umajin",
        ".htm" : "text/html",
        ".m2a" : "audio/mpeg",
        ".fig" : "application/x-xfig",
        ".sig" : "application/pgp-signature",
        ".sid" : "audio/prs.sid",
        ".cab" : "application/vnd.ms-cab-compressed",
        ".tsv" : "text/tab-separated-values",
        ".so" : "application/octet-stream",
        ".ltx" : "text/x-tex",
        ".tsp" : "application/dsptype",
        ".ltf" : "application/vnd.frogans.ltf",
        ".wbs" : "application/vnd.criticaltools.wbs+xml",
        ".prc" : "application/vnd.palm",
        ".pre" : "application/vnd.lotus-freelance",
        ".prf" : "application/pics-rules",
        ".oprc" : "application/vnd.palm",
        ".c3d" : "chemical/x-chem3d",
        ".dd2" : "application/vnd.oma.dd2+xml",
        ".cat" : "application/vnd.ms-pki.seccat",
        ".dms" : "application/x-dms",
        ".xla" : "application/vnd.ms-excel",
        ".fti" : "application/vnd.anser-web-funds-transfer-initiation",
        ".ief" : "image/ief",
        ".mp4s" : "application/mp4",
        ".qwt" : "application/vnd.quark.quarkxpress",
        ".c4d" : "application/vnd.clonk.c4group",
        ".c4g" : "application/vnd.clonk.c4group",
        ".c4f" : "application/vnd.clonk.c4group",
        ".texinfo" : "application/x-texinfo",
        ".mp4a" : "audio/mp4",
        ".dmg" : "application/x-apple-diskimage",
        ".c4p" : "application/vnd.clonk.c4group",
        ".c4u" : "application/vnd.clonk.c4group",
        ".vis" : "application/vnd.visionary",
        ".viv" : "video/vnd.vivo",
        ".listafp" : "application/vnd.ibm.modcap",
        ".ddd" : "application/vnd.fujixerox.ddd",
        ".tmo" : "application/vnd.tmobile-livetv",
        ".ext" : "application/vnd.novadigm.ext",
        ".csml" : "chemical/x-csml",
        ".mus" : "application/vnd.musician",
        ".exe" : "application/x-msdos-program",
        ".xpw" : "application/vnd.intercon.formnet",
        ".wsc" : "text/scriptlet",
        ".xpr" : "application/vnd.is-xpr",
        ".xps" : "application/vnd.ms-xpsdocument",
        ".dsc" : "text/prs.lines.tag",
        ".xpx" : "application/vnd.intercon.formnet",
        ".mscml" : "application/mediaservercontrol+xml",
        ".rep" : "application/vnd.businessobjects",
        ".xpm" : "image/x-xpixmap",
        ".mpeg" : "video/mpeg",
        ".mxf" : "application/mxf",
        ".spq" : "application/scvp-vp-request",
        ".spp" : "application/scvp-vp-response",
        ".ami" : "application/vnd.amiga.ami",
        ".fm" : "application/x-maker",
        ".ram" : "audio/x-pn-realaudio",
        ".sgml" : "text/sgml",
        ".spf" : "application/vnd.yamaha.smaf-phrase",
        ".cil" : "application/vnd.ms-artgalry",
        ".spc" : "chemical/x-galactic-spc",
        ".spl" : "application/x-futuresplash",
        ".bat" : "application/x-msdos-program",
        ".clkx" : "application/vnd.crick.clicker",
        ".portpkg" : "application/vnd.macports.portpkg",
        ".emb" : "chemical/x-embl-dl-nucleotide",
        ".eml" : "message/rfc822",
        ".cbin" : "chemical/x-cactvs-binary",
        ".diff" : "text/plain",
        ".gac" : "application/vnd.groove-account",
        ".cww" : "application/prs.cww",
        ".gal" : "chemical/x-gaussian-log",
        ".efif" : "application/vnd.picsel",
        ".isp" : "application/x-internet-signup",
        ".gjc" : "chemical/x-gaussian-input",
        ".wad" : "application/x-doom",
        ".saf" : "application/vnd.yamaha.smaf-audio",
        ".txf" : "application/vnd.mobius.txf",
        ".utz" : "application/vnd.uiq.theme",
        ".txd" : "application/vnd.genomatix.tuxedo",
        ".m2v" : "video/mpeg",
        ".art" : "image/x-jg",
        ".tk" : "text/x-tcl",
        ".wav" : "audio/x-wav",
        ".rsd" : "application/rsd+xml",
        ".xbm" : "image/x-xbitmap",
        ".txt" : "text/plain",
        ".jlt" : "application/vnd.hp-jlyt",
        ".xbd" : "application/vnd.fujixerox.docuworks.binder",
        ".wax" : "audio/x-ms-wax",
        ".mlp" : "application/vnd.dolby.mlp",
        ".sc" : "application/vnd.ibm.secure-container",
        ".twd" : "application/vnd.simtech-mindmapper",
        ".dna" : "application/vnd.dna",
        ".ts" : "text/texmacs",
        ".tr" : "application/x-troff",
        ".distz" : "application/octet-stream",
        ".fbdoc" : "application/x-maker",
        ".tm" : "text/texmacs",
        ".smil" : "application/smil",
        ".fnc" : "application/vnd.frogans.fnc",
        ".sh" : "text/x-sh",
        ".et3" : "application/vnd.eszigno3+xml",
        ".xif" : "image/vnd.xiff",
        ".daf" : "application/vnd.mobius.daf",
        ".ez2" : "application/vnd.ezpix-album",
        ".old" : "application/x-trash",
        ".cer" : "chemical/x-cerius",
        ".smf" : "application/vnd.stardivision.math",
        ".ufd" : "application/vnd.ufdl",
        ".cef" : "chemical/x-cxf",
        ".smi" : "application/smil",
        ".bsd" : "chemical/x-crossfire",
        ".ctab" : "chemical/x-cactvs-binary",
        ".inp" : "chemical/x-gamess-input",
        ".sfs" : "application/vnd.spotfire.sfs",
        ".ecma" : "application/ecmascript",
        ".etx" : "text/x-setext",
        ".iges" : "model/iges",
        ".dxr" : "application/x-director",
        ".dxp" : "application/vnd.spotfire.dxp",
        ".png" : "image/png",
        ".mhtml" : "message/rfc822",
        ".tar" : "application/x-tar",
        ".pnm" : "image/x-portable-anymap",
        ".taz" : "application/x-gtar",
        ".pnt" : "image/x-macpaint",
        ".mqy" : "application/vnd.mobius.mqy",
        ".dxf" : "image/vnd.dxf",
        ".rnc" : "application/relax-ng-compact-syntax",
        ".tao" : "application/vnd.tao.intent-module-archive",
        ".323" : "text/h323",
        ".wvx" : "video/x-ms-wvx",
        ".gdl" : "model/vnd.gdl",
        ".hpgl" : "application/vnd.hp-hpgl",
        ".bak" : "application/x-trash",
        ".jng" : "image/x-jng",
        ".ecelp9600" : "audio/vnd.nuera.ecelp9600",
        ".wbxml" : "application/vnd.wap.wbxml",
        ".chrt" : "application/x-kchart",
        ".wsdl" : "application/wsdl+xml",
        ".dwg" : "image/vnd.dwg",
        ".dwf" : "model/vnd.dwf",
        ".jmz" : "application/x-jmol",
        ".fg5" : "application/vnd.fujitsu.oasysgp",
        ".oza" : "application/x-oz-application",
        ".cc" : "text/x-c++src",
        ".cu" : "application/cu-seeme",
        ".rxn" : "chemical/x-mdl-rxnfile",
        ".ei6" : "application/vnd.pg.osasli",
        ".sty" : "text/x-tex",
        ".rpm" : "application/x-redhat-package-manager",
        ".mcd" : "application/vnd.mcd",
        ".nnd" : "application/vnd.noblenet-directory",
        ".nlu" : "application/vnd.neurolanguage.nlu",
        ".str" : "application/vnd.pg.format",
        ".stw" : "application/vnd.sun.xml.writer.template",
        ".mjp2" : "video/mj2",
        ".xhvml" : "application/xv+xml",
        ".stk" : "application/hyperstudio",
        ".crl" : "application/x-pkcs7-crl",
        ".semd" : "application/vnd.semd",
        ".nnw" : "application/vnd.noblenet-web",
        ".semf" : "application/vnd.semf",
        ".stc" : "application/vnd.sun.xml.calc.template",
        ".crd" : "application/x-mscardfile",
        ".std" : "application/vnd.sun.xml.draw.template",
        ".m1v" : "video/mpeg",
        ".stf" : "application/vnd.wt.stf",
        ".icz" : "text/calendar",
        ".mime" : "message/rfc822",
        ".hin" : "chemical/x-hin",
        ".avi" : "video/x-msvideo",
        ".fgd" : "application/x-director",
        ".istr" : "chemical/x-isostar",
        ".cascii" : "chemical/x-cactvs-binary",
        ".qfx" : "application/vnd.intu.qfx",
        ".wdb" : "application/vnd.ms-works",
        ".cla" : "application/vnd.claymore",
        ".pwn" : "application/vnd.3m.post-it-notes",
        ".hxx" : "text/x-c++hdr",
        ".wml" : "text/vnd.wap.wml",
        ".mht" : "message/rfc822",
        ".wma" : "audio/x-ms-wma",
        ".wmf" : "application/x-msmetafile",
        ".wmd" : "application/x-ms-wmd",
        ".wmz" : "application/x-ms-wmz",
        ".clp" : "application/x-msclip",
        ".wmx" : "video/x-ms-wmx",
        ".gamin" : "chemical/x-gamess-input",
        ".pwz" : "application/vnd.ms-powerpoint",
        ".hpp" : "text/x-c++hdr",
        ".mc1" : "application/vnd.medcalcdata",
        ".m13" : "application/x-msmediaview",
        ".m14" : "application/x-msmediaview",
        ".dist" : "application/octet-stream",
        ".nml" : "application/vnd.enliven",
        ".kpt" : "application/x-kpresenter",
        ".kpr" : "application/x-kpresenter",
        ".src" : "application/x-wais-source",
        ".sik" : "application/x-trash",
        ".oa2" : "application/vnd.fujitsu.oasys2",
        ".oa3" : "application/vnd.fujitsu.oasys3",
        ".gtar" : "application/x-gtar",
        ".p7m" : "application/pkcs7-mime",
        ".nws" : "message/rfc822",
        ".deb" : "application/x-debian-package",
        ".p7c" : "application/pkcs7-mime",
        ".p7b" : "application/x-pkcs7-certificates",
        ".book" : "application/x-maker",
        ".def" : "text/plain",
        ".mts" : "model/vnd.mts",
        ".cls" : "text/x-tex",
        ".nwc" : "application/x-nwc",
        ".bpk" : "application/octet-stream",
        ".ez" : "application/andrew-inset",
        ".der" : "application/x-x509-ca-cert",
        ".p7s" : "application/pkcs7-signature",
        ".p7r" : "application/x-pkcs7-certreqresp",
        ".pntg" : "image/x-macpaint",
        ".eps" : "application/postscript",
        ".xul" : "application/vnd.mozilla.xul+xml",
        ".ace" : "application/x-ace-compressed",
        ".hh" : "text/x-c++hdr",
        ".cdr" : "image/x-coreldraw",
        ".pdb" : "chemical/x-pdb",
        ".dfac" : "application/vnd.dreamfactory",
        ".hs" : "text/x-haskell",
        ".acu" : "application/vnd.acucobol",
        ".wmlsc" : "application/vnd.wap.wmlscriptc",
        ".oas" : "application/vnd.fujitsu.oasys",
        ".c++" : "text/x-c++src",
        ".tex" : "text/x-tex",
        ".wri" : "application/x-mswrite",
        ".ica" : "application/x-ica",
        ".irp" : "application/vnd.irepository.package+xml",
        ".wrl" : "x-world/x-vrml",
        ".oti" : "application/vnd.oasis.opendocument.image-template",
        ".ssf" : "application/vnd.epson.ssf",
        ".sitx" : "application/x-stuffitx",
        ".oth" : "application/vnd.oasis.opendocument.text-web",
        ".xpi" : "application/x-xpinstall",
        ".rtx" : "text/richtext",
        ".moc" : "text/x-moc",
        ".irm" : "application/vnd.ibm.rights-management",
        ".cdf" : "application/x-cdf",
        ".joda" : "application/vnd.joost.joda-archive",
        ".rpst" : "application/vnd.nokia.radio-preset",
        ".gsm" : "audio/x-gsm",
        ".fdf" : "application/vnd.fdf",
        ".elc" : "application/octet-stream",
        ".man" : "application/x-troff-man",
        ".rpss" : "application/vnd.nokia.radio-presets",
        ".pac" : "application/x-ns-proxy-autoconfig",
        ".flac" : "application/x-flac",
        ".hps" : "application/vnd.hp-hps",
        ".mfm" : "application/vnd.mfmp",
        ".pas" : "text/x-pascal",
        ".pat" : "image/x-coreldrawpattern",
        ".fbs" : "image/vnd.fastbidsheet",
        ".gim" : "application/vnd.groove-identity-message",
        ".kfo" : "application/vnd.kde.kformula",
        ".moo" : "chemical/x-mopac-out",
        ".mol" : "chemical/x-mdl-molfile",
        ".ims" : "application/vnd.ms-ims",
        ".gif" : "image/gif",
        ".lrm" : "application/vnd.ms-lrm",
        ".cdkey" : "application/vnd.mediastation.cdkey",
        ".atomcat" : "application/atomcat+xml",
        ".les" : "application/vnd.hhe.lesson-player",
        ".shtml" : "text/html",
        ".djvu" : "image/vnd.djvu",
        ".rtf" : "text/rtf",
        ".fchk" : "chemical/x-gaussian-checkpoint",
        ".mop" : "chemical/x-mopac-input",
        ".mov" : "video/quicktime",
        ".xcf" : "application/x-xcf",
        ".twds" : "application/vnd.simtech-mindmapper",
        ".movie" : "video/x-sgi-movie",
        ".uls" : "text/iuls",
        ".qt" : "video/quicktime",
        ".pyc" : "application/x-python-code",
        ".sv4cpio" : "application/x-sv4cpio",
        ".rms" : "application/vnd.jcp.javame.midlet-rms",
        ".com" : "application/x-msdos-program",
        ".cac" : "chemical/x-cache",
        ".mathml" : "application/mathml+xml",
        ".key" : "application/pgp-keys",
        ".psp" : "text/x-psp",
        ".wiz" : "application/msword",
        ".vcd" : "application/x-cdlink",
        ".vcg" : "application/vnd.groove-vcard",
        ".vcf" : "text/x-vcard",
        ".json" : "application/json",
        ".shf" : "application/shf+xml",
        ".cdbcmsg" : "application/vnd.contact.cmsg",
        ".tpt" : "application/vnd.trid.tpt",
        ".psb" : "application/vnd.3gpp.pic-bw-small",
        ".vxml" : "application/voicexml+xml",
        ".tpl" : "application/vnd.groove-tool-template",
        ".htke" : "application/vnd.kenameaapp",
        ".vcx" : "application/vnd.vcx",
        ".xhtml" : "application/xhtml+xml",
        ".midi" : "audio/midi",
        ".tiff" : "image/tiff",
        ".odg" : "application/vnd.oasis.opendocument.graphics",
        ".texi" : "application/x-texinfo",
        ".oda" : "application/oda",
        ".ustar" : "application/x-ustar",
        ".ssml" : "application/ssml+xml",
        ".odb" : "application/vnd.oasis.opendocument.database",
        ".odm" : "application/vnd.oasis.opendocument.text-master",
        ".xvm" : "application/xv+xml",
        ".see" : "application/vnd.seemail",
        ".odi" : "application/vnd.oasis.opendocument.image",
        ".mpkg" : "application/vnd.apple.installer+xml",
        ".odt" : "application/vnd.oasis.opendocument.text",
        ".3g2" : "video/3gpp2",
        ".odp" : "application/vnd.oasis.opendocument.presentation",
        ".ods" : "application/vnd.oasis.opendocument.spreadsheet",
        ".stl" : "application/vnd.ms-pki.stl",
        ".msi" : "application/x-msi",
        ".ser" : "application/java-serialized-object",
        ".text" : "text/plain",
        ".ros" : "chemical/x-rosdal",
        ".mpn" : "application/vnd.mophun.application",
        ".mpm" : "application/vnd.blueice.multipass",
        ".mpc" : "chemical/x-mopac-input",
        ".mpa" : "video/mpeg",
        ".mpg" : "video/mpeg",
        ".mng" : "video/x-mng",
        ".mpe" : "video/mpeg",
        ".jdx" : "chemical/x-jcamp-dx",
        ".mpy" : "application/vnd.ibm.minipay",
        ".pot" : "text/plain",
        ".ps" : "application/postscript",
        ".g3" : "image/g3fax",
        ".mpp" : "application/vnd.ms-project",
        ".xspf" : "application/xspf+xml",
        ".nsf" : "application/vnd.lotus-notes",
        ".wmlc" : "application/vnd.wap.wmlc",
        ".dpg" : "application/vnd.dpgraph",
        ".nb" : "application/mathematica",
        ".wmls" : "text/vnd.wap.wmlscript",
        ".mmod" : "chemical/x-macromodel-input",
        ".kon" : "application/vnd.kde.kontour",
        ".karbon" : "application/vnd.kde.karbon",
        ".prt" : "chemical/x-ncbi-asn1-ascii",
        ".sw" : "chemical/x-swissprot",
        ".alc" : "chemical/x-alchemy",
        ".gf" : "application/x-tex-gf",
        ".pfx" : "application/x-pkcs12",
        ".m4a" : "audio/mpeg",
        ".jnlp" : "application/x-java-jnlp-file",
        ".gl" : "video/gl",
        ".ivp" : "application/vnd.immervision-ivp",
        ".ivu" : "application/vnd.immervision-ivu",
        ".pfr" : "application/font-tdpfr",
        ".mcif" : "chemical/x-mmcif",
        ".m4v" : "video/mp4",
        ".m4u" : "video/vnd.mpegurl",
        ".swf" : "application/x-shockwave-flash",
        ".m4p" : "audio/mp4a-latm",
        ".mp3" : "audio/mpeg",
        ".mp2" : "audio/mpeg",
        ".pfa" : "application/x-font",
        ".pfb" : "application/x-font",
        ".mp4" : "video/mp4",
        ".cxf" : "chemical/x-cxf",
        ".hvp" : "application/vnd.yamaha.hv-voice",
        ".rm" : "audio/x-pn-realaudio",
        ".hvs" : "application/vnd.yamaha.hv-script",
        ".scpt" : "application/octet-stream",
        ".ra" : "audio/x-realaudio",
        ".sbml" : "application/sbml+xml",
        ".gsf" : "application/x-font",
        ".hvd" : "application/vnd.yamaha.hv-dic",
        ".cmdf" : "chemical/x-cmdf",
        ".wcm" : "application/vnd.ms-works",
        ".sxd" : "application/vnd.sun.xml.draw",
        ".rs" : "application/rls-services+xml",
        ".rq" : "application/sparql-query",
        ".sxg" : "application/vnd.sun.xml.writer.global",
        ".xop" : "application/xop+xml",
        ".skd" : "application/x-koan",
        ".sis" : "application/vnd.symbian.install",
        ".h263" : "video/h263",
        ".skm" : "application/x-koan",
        ".h261" : "video/h261",
        ".h264" : "video/h264",
        ".skt" : "application/x-koan",
        ".plf" : "application/vnd.pocketlearn",
        ".skp" : "application/x-koan",
        ".ufdl" : "application/vnd.ufdl",
        ".for" : "text/x-fortran",
        ".lvp" : "audio/vnd.lucent.voice",
        ".hqx" : "application/mac-binhex40",
        ".swfl" : "application/x-shockwave-flash",
        ".ksp" : "application/x-kspread",
        ".sit" : "application/x-stuffit",
        ".doc" : "application/msword",
        ".uu" : "text/x-uuencode",
        ".shar" : "application/x-shar",
        ".ptid" : "application/vnd.pvi.ptid1",
        ".ksh" : "text/plain",
        ".ccxml" : "application/ccxml+xml",
        ".dot" : "application/msword",
        ".cdy" : "application/vnd.cinderella",
        ".cdx" : "chemical/x-cdx",
        ".slt" : "application/vnd.epson.salt",
        ".fvt" : "video/vnd.fvt",
        ".vor" : "application/vnd.stardivision.writer",
        ".ics" : "text/calendar",
        ".o" : "application/x-object",
        ".cdt" : "image/x-coreldrawtemplate",
        ".ktr" : "application/vnd.kahootz",
        ".qps" : "application/vnd.publishare-delta-tree",
        ".ico" : "image/x-icon",
        ".sti" : "application/vnd.sun.xml.impress.template",
        ".uoml" : "application/vnd.uoml+xml",
        ".ktz" : "application/vnd.kahootz",
        ".ice" : "x-conference/x-cooltalk",
        ".wbmp" : "image/vnd.wap.wbmp",
        ".in" : "text/plain",
        ".edm" : "application/vnd.novadigm.edm",
        ".mp4v" : "video/mp4",
        ".grv" : "application/vnd.groove-injector",
        ".list" : "text/plain",
        ".esf" : "application/vnd.epson.esf",
        ".abw" : "application/x-abiword",
        ".wspolicy" : "application/wspolicy+xml",
        ".mpga" : "audio/mpeg",
        ".pki" : "application/pkixcmp",
        ".hdf" : "application/x-hdf",
        ".davmount" : "application/davmount+xml",
        ".xpdl" : "application/xml",
        ".pkg" : "application/octet-stream",
        ".zaz" : "application/vnd.zzazz.deck+xml",
        ".wqd" : "application/vnd.wqd",
        ".log" : "text/plain",
        ".cxx" : "text/x-c++src",
        ".srx" : "application/sparql-results+xml",
        ".box" : "application/vnd.previewsystems.box",
        ".boz" : "application/x-bzip2",
        ".vcs" : "text/x-vcalendar",
        ".oxt" : "application/vnd.openofficeorg.extension",
        ".pbd" : "application/vnd.powerbuilder6",
        ".bh2" : "application/vnd.fujitsu.oasysprs",
        ".h++" : "text/x-c++hdr",
        ".mpg4" : "video/mp4",
        ".psd" : "image/x-photoshop",
        ".gcd" : "text/x-pcs-gcd",
        ".pbm" : "image/x-portable-bitmap",
        ".gcf" : "application/x-graphing-calculator",
        ".es3" : "application/vnd.eszigno3+xml",
        ".qbo" : "application/vnd.intu.qbo",
        ".vrml" : "x-world/x-vrml",
        ".msty" : "application/vnd.muvee.style",
        ".dtd" : "application/xml-dtd",
        ".gcg" : "chemical/x-gcg8-sequence",
        ".pclxl" : "application/vnd.hp-pclxl",
        ".xdp" : "application/vnd.adobe.xdp+xml",
        ".apr" : "application/vnd.lotus-approach",
        ".mbk" : "application/vnd.mobius.mbk",
        ".cdxml" : "application/vnd.chemdraw+xml",
        ".wpl" : "application/vnd.ms-wpl",
        ".kar" : "audio/midi",
        ".org" : "application/vnd.lotus-organizer",
        ".xslt" : "application/xslt+xml",
        ".aiff" : "audio/x-aiff",
        ".vrm" : "x-world/x-vrml",
        ".aifc" : "audio/x-aiff",
        ".xdm" : "application/vnd.syncml.dm+xml",
        ".gqf" : "application/vnd.grafeq",
        ".crt" : "application/x-x509-ca-cert",
        ".flx" : "text/vnd.fmi.flexstor",
        ".fly" : "text/vnd.fly",
        ".kne" : "application/vnd.kinar",
        ".edx" : "application/vnd.novadigm.edx",
        ".flv" : "video/x-flv",
        ".flw" : "application/vnd.kde.kivio",
        ".html" : "text/html",
        ".susp" : "application/vnd.sus-calendar",
        ".ez3" : "application/vnd.ezpix-package",
        ".knp" : "application/vnd.kinar",
        ".gqs" : "application/vnd.grafeq",
        ".hbci" : "application/vnd.hbci",
        ".ins" : "application/x-internet-signup",
        ".pkipath" : "application/pkix-pkipath",
        ".lzx" : "application/x-lzx",
        ".odc" : "application/vnd.oasis.opendocument.chart",
        ".nns" : "application/vnd.noblenet-sealer",
        ".ppt" : "application/vnd.ms-powerpoint",
        ".zmt" : "chemical/x-mopac-input",
        ".pps" : "application/vnd.ms-powerpoint",
        ".ppm" : "image/x-portable-pixmap",
        ".lzh" : "application/x-lzh",
        ".latex" : "application/x-latex",
        ".ppd" : "application/vnd.cups-ppd",
        ".cgm" : "image/cgm",
        ".ppa" : "application/vnd.ms-powerpoint",
        ".fpx" : "image/vnd.fpx",
        ".igl" : "application/vnd.igloader",
        ".mbox" : "application/mbox",
        ".frm" : "application/x-maker",
        ".kwt" : "application/x-kword",
        ".dcr" : "application/x-director",
        ".mp2a" : "audio/mpeg",
        ".igx" : "application/vnd.micrografx.igx",
        ".kwd" : "application/x-kword",
        ".igs" : "model/iges",
        ".xdw" : "application/vnd.fujixerox.docuworks",
        ".qti" : "image/x-quicktime",
        ".jad" : "text/vnd.sun.j2me.app-descriptor",
        ".mwf" : "application/vnd.mfer",
        ".qtl" : "application/x-quicktimeplayer",
        ".npx" : "image/vnd.net-fpx",
        ".jam" : "application/vnd.jam",
        ".rlc" : "image/vnd.fujixerox.edmics-rlc",
        ".svgz" : "image/svg+xml",
        ".bz2" : "application/x-bzip2",
        ".jar" : "application/java-archive",
        ".fch" : "chemical/x-gaussian-checkpoint",
        ".ogg" : "application/ogg",
        ".afp" : "application/vnd.ibm.modcap",
        ".f90" : "text/x-fortran",
        ".ms" : "application/x-troff-ms",
        ".rgb" : "image/x-rgb",
        ".mxl" : "application/vnd.recordare.musicxml",
        ".mxs" : "application/vnd.triscape.mxs",
        ".gram" : "application/srgs",
        ".me" : "application/x-troff-me",
        ".mb" : "application/mathematica",
        ".mxu" : "video/vnd.mpegurl",
        ".ma" : "application/mathematica",
        ".qam" : "application/vnd.epson.quickanime",
        ".mm" : "application/x-freemind",
        ".dl" : "video/dl",
        ".mesh" : "model/mesh",
        ".pgp" : "application/pgp-signature",
        ".pgn" : "application/x-chess-pgn",
        ".pgm" : "image/x-portable-graymap",
        ".xyz" : "chemical/x-xyz",
        ".svg" : "image/svg+xml",
        ".svd" : "application/vnd.svd",
        ".atom" : "application/atom+xml",
        ".dp" : "application/vnd.osgi.dp",
        ".roff" : "application/x-troff",
        ".unityweb" : "application/vnd.unity",
        ".123" : "application/vnd.lotus-1-2-3",
        ".dv" : "video/dv",
        ".cub" : "chemical/x-gaussian-cube",
        ".eol" : "audio/vnd.digital-winds",
        ".frame" : "application/x-maker",
        ".qtif" : "image/x-quicktime",
        ".eot" : "application/vnd.ms-fontobject",
        ".gau" : "chemical/x-gaussian-input",
        ".mac" : "image/x-macpaint",
        ".dat" : "chemical/x-mopac-input",
        ".mag" : "application/vnd.ecowin.chart",
        ".lsf" : "video/x-la-asf",
        ".iif" : "application/vnd.shana.informed.interchange",
        ".atx" : "application/vnd.antix.game-component",
        ".mmf" : "application/vnd.smaf",
        ".mny" : "application/x-msmoney",
        ".iii" : "application/x-iphone",
        ".pyo" : "application/x-python-code",
        ".ghf" : "application/vnd.groove-help",
        ".cpio" : "application/x-cpio",
        ".rdf" : "application/rdf+xml",
        ".setreg" : "application/set-registration-initiation",
        ".atc" : "application/vnd.acucorp",
        ".lsx" : "video/x-la-asf",
        ".ecelp4800" : "audio/vnd.nuera.ecelp4800",
        ".sema" : "application/vnd.sema",
        ".val" : "chemical/x-ncbi-asn1-binary",
        ".dll" : "application/x-msdos-program",
        ".sd2" : "audio/x-sd2",
        ".rif" : "application/reginfo+xml",
        ".sct" : "text/scriptlet",
        ".scq" : "application/scvp-cv-request",
        ".scs" : "application/scvp-cv-response",
        ".scm" : "application/vnd.lotus-screencam",
        ".xfdl" : "application/vnd.xfdl",
        ".scd" : "application/x-msschedule",
        ".xfdf" : "application/vnd.adobe.xfdf",
        ".xwd" : "image/x-xwindowdump",
        ".mif" : "application/x-mif",
        ".sda" : "application/vnd.stardivision.draw",
        ".sdc" : "application/vnd.stardivision.calc",
        ".sdd" : "application/vnd.stardivision.impress",
        ".sdf" : "chemical/x-mdl-sdfile",
        ".js" : "application/x-javascript",
        ".sdp" : "application/vnd.stardivision.impress",
        ".sdw" : "application/vnd.stardivision.writer",
        ".plb" : "application/vnd.3gpp.pic-bw-large",
        ".plc" : "application/vnd.mobius.plc",
        ".ipk" : "application/vnd.shana.informed.package",
        ".%" : "application/x-trash",
        ".3dml" : "text/vnd.in3d.3dml",
        ".qxt" : "application/vnd.quark.quarkxpress",
        ".n-gage" : "application/vnd.nokia.n-gage.symbian.install",
        ".wtb" : "application/vnd.webturbo",
        ".msf" : "application/vnd.epson.msf",
        ".pls" : "audio/x-scpls",
        ".flo" : "application/vnd.micrografx.flo",
        ".tgf" : "chemical/x-mdl-tgf",
        ".tgz" : "application/x-gtar",
        ".lhs" : "text/x-literate-haskell",
        ".msl" : "application/vnd.mobius.msl",
        ".qxd" : "application/vnd.quark.quarkxpress",
        ".qxb" : "application/vnd.quark.quarkxpress",
        ".msh" : "model/mesh",
        ".fli" : "video/fli",
        ".lha" : "application/x-lha",
        ".cpa" : "chemical/x-compass",
        ".au" : "audio/basic",
        ".pcl" : "application/vnd.hp-pcl",
        ".cpt" : "image/x-corelphotopaint",
        ".jpg" : "image/jpeg",
        ".mdb" : "application/msaccess",
        ".pct" : "image/x-pict",
        ".jpm" : "video/jpm",
        ".mpega" : "audio/mpeg",
        ".pcx" : "image/pcx",
        ".mdi" : "image/vnd.ms-modi",
        ".zip" : "application/zip",
        ".xtel" : "chemical/x-xtel",
        ".vss" : "application/vnd.visio",
        ".m3u" : "audio/x-mpegurl",
        ".clkk" : "application/vnd.crick.clicker.keyboard",
        ".vst" : "application/vnd.visio",
        ".vsw" : "application/vnd.visio",
        ".class" : "application/java-vm",
        ".torrent" : "application/x-bittorrent",
        ".hlp" : "application/winhlp",
        ".mj2" : "video/mj2",
        ".m3a" : "audio/mpeg",
        ".asc" : "text/plain",
        ".qxl" : "application/vnd.quark.quarkxpress",
        ".asf" : "video/x-ms-asf",
        ".vsd" : "application/vnd.visio",
        ".vsf" : "application/vnd.vsf",
        ".clkw" : "application/vnd.crick.clicker.wordbank",
        ".xo" : "application/vnd.olpc-sugar",
        ".clkt" : "application/vnd.crick.clicker.template",
        ".asn" : "chemical/x-ncbi-asn1-spec",
        ".aso" : "chemical/x-ncbi-asn1-binary",
        ".mmr" : "image/vnd.fujixerox.edmics-mmr",
        ".asm" : "text/x-asm",
        ".uri" : "text/uri-list",
        ".jp2" : "image/jp2",
        ".xlm" : "application/vnd.ms-excel",
        ".xlb" : "application/vnd.ms-excel",
        ".xlc" : "application/vnd.ms-excel",
        ".tcap" : "application/vnd.3gpp2.tcap",
        ".sd" : "chemical/x-mdl-sdfile",
        ".cif" : "chemical/x-cif",
        ".wz" : "application/x-wingz",
        ".xls" : "application/vnd.ms-excel",
        ".cii" : "application/vnd.anser-web-certificate-issue-initiation",
        ".xlw" : "application/vnd.ms-excel",
        ".xlt" : "application/vnd.ms-excel",
        ".fb" : "application/x-maker",
        ".3gp" : "video/3gpp",
        ".wks" : "application/vnd.ms-works",
        ".wmv" : "video/x-ms-wmv",
        ".gtw" : "model/vnd.gtw",
        ".dx" : "chemical/x-jcamp-dx",
        ".gtm" : "application/vnd.groove-tool-message",
        ".trm" : "application/x-msterminal",
        ".kin" : "chemical/x-kinemage",
        ".urls" : "text/uri-list",
        ".kil" : "application/x-killustrator",
        ".pub" : "application/x-mspublisher",
        ".imp" : "application/vnd.accpac.simply.imp",
        ".lwp" : "application/vnd.lotus-wordpro",
        ".odf" : "application/vnd.oasis.opendocument.formula",
        ".tra" : "application/vnd.trueapp",
        ".fsc" : "application/vnd.fsc.weblaunch",
        ".ifm" : "application/vnd.shana.informed.formdata",
        ".mpt" : "application/vnd.ms-project",
        ".sgf" : "application/x-go-sgf",
        ".ifb" : "text/calendar",
        ".sgl" : "application/vnd.stardivision.writer-global",
        ".sgm" : "text/sgml",
        ".lbd" : "application/vnd.llamagraphics.life-balance.desktop",
        ".lbe" : "application/vnd.llamagraphics.life-balance.exchange+xml",
        ".maker" : "application/x-maker",
        ".fst" : "image/vnd.fst",
        ".mcm" : "chemical/x-macmolecule",
        ".tif" : "image/tiff",
        ".otp" : "application/vnd.oasis.opendocument.presentation-template",
        ".pcf" : "application/x-font",
        ".rmi" : "audio/midi",
        ".wp5" : "application/wordperfect5.1",
        ".f77" : "text/x-fortran",
        ".pic" : "image/x-pict",
        ".cache" : "chemical/x-cache",
        ".mvb" : "chemical/x-mopac-vib",
        ".qwd" : "application/vnd.quark.quarkxpress",
        ".ngdat" : "application/vnd.nokia.n-gage.data",
        ".rmp" : "audio/x-pn-realaudio-plugin",
        ".wk" : "application/x-123",
        ".acutc" : "application/vnd.acucorp",
        ".xsm" : "application/vnd.syncml+xml",
        ".xsl" : "application/xml",
        ".sxw" : "application/vnd.sun.xml.writer",
        ".spot" : "text/vnd.in3d.spot",
        ".nc" : "application/x-netcdf",
        ".fzs" : "application/vnd.fuzzysheet",
        ".sxm" : "application/vnd.sun.xml.math",
        ".mseq" : "application/vnd.mseq",
        ".sxi" : "application/vnd.sun.xml.impress",
        ".bib" : "text/x-bibtex",
        ".aep" : "application/vnd.audiograph",
        ".bin" : "application/octet-stream",
        ".rdz" : "application/vnd.data-vision.rdz",
        ".pcf.Z" : "application/x-font",
        ".uris" : "text/uri-list",
        ".sxc" : "application/vnd.sun.xml.calc",
        ".h" : "text/x-chdr",
        ".wps" : "application/vnd.ms-works",
        ".itp" : "application/vnd.shana.informed.formtemplate",
        ".jpe" : "image/jpeg",
        ".a" : "application/octet-stream",
        ".b" : "chemical/x-molconn-Z",
        ".c" : "text/x-csrc",
        ".rcprofile" : "application/vnd.ipunplugged.rcprofile",
        ".udeb" : "application/x-debian-package",
        ".f" : "text/x-fortran",
        ".fe_launch" : "application/vnd.denovo.fcselayout-link",
        ".vtu" : "model/vnd.vtu",
        ".wpd" : "application/wordperfect",
        ".~" : "application/x-trash",
        ".mxml" : "application/xv+xml",
        ".p" : "text/x-pascal",
        ".s" : "text/x-asm",
        ".t" : "application/x-troff",
        ".ai" : "application/postscript",
        ".cpp" : "text/x-c++src",
        ".xenc" : "application/xenc+xml",
        ".btif" : "image/prs.btif",
        ".gnumeric" : "application/x-gnumeric",
        ".kia" : "application/vnd.kidspiration",
        ".conf" : "text/plain",
        ".xvml" : "application/xv+xml",
        ".x3d" : "application/vnd.hzn-3d-crossword",
        ".mol2" : "chemical/x-mol2",
        ".ctx" : "chemical/x-ctx",
        ".xar" : "application/vnd.xara",
        ".ent" : "chemical/x-pdb",
        ".zmm" : "application/vnd.handheld-entertainment+xml",
        ".sv4crc" : "application/x-sv4crc",
        ".cmc" : "application/vnd.cosmocaller",
        ".cml" : "chemical/x-cml",
        ".pvb" : "application/vnd.3gpp.pic-bw-var",
        ".jpeg" : "image/jpeg",
        ".mgz" : "application/vnd.proteus.magazine",
        ".mid" : "audio/midi",
        ".cmp" : "application/vnd.yellowriver-custom-menu",
        ".chat" : "application/x-chat",
        ".cmx" : "image/x-cmx",
        ".mml" : "text/mathml",
        ".kml" : "application/vnd.google-earth.kml+xml",
        ".dump" : "application/octet-stream",
        ".gph" : "application/vnd.flographit",
        ".xht" : "application/xhtml+xml",
        ".dif" : "video/dv",
        ".grxml" : "application/srgs+xml",
        ".dic" : "text/x-c",
        ".kmz" : "application/vnd.google-earth.kmz",
        ".gpt" : "chemical/x-mopac-graph",
        ".wm" : "video/x-ms-wm",
        ".dis" : "application/vnd.mobius.dis",
        ".dir" : "application/x-director",
        ".curl" : "application/vnd.curl",
        ".setpay" : "application/set-payment-initiation",
        ".cod" : "application/vnd.rim.cod",
        ".vmd" : "chemical/x-vmd",
        ".jpgm" : "video/jpm",
        ".snd" : "audio/basic",
        ".mmd" : "chemical/x-macromodel-input",
        ".pict" : "image/pict",
        ".jpgv" : "video/jpeg",
        ".ftc" : "application/vnd.fluxtime.clip",
        ".pqa" : "application/vnd.palm",
        ".java" : "text/x-java",
        ".vms" : "chemical/x-vamas-iso14976",
        ".asx" : "video/x-ms-asf"
        ];

        mimes.rehash;
	}
}
