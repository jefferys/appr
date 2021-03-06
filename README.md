<!-- README.md is generated from README.Rmd. Please edit that file -->
appr - Application framework for R
==================================

A framework for building pluggable command line R applications based on descriptor files. Automatically generates a command line interface that supports commands from installed packages by configuring them in a descriptor file. Supports options at the application and command level, including configuration files.

Application user
----------------

A user of an appr application has to install the application package. It should have `appr` as a dependency, so that will be installed if not already present. This is no different that using any R package.

``` r
install.packages( "HelloThere" )
#> ...
```

The application provided by the package can now be run from the command line using R and appr, usually by using its package name. Application specific ommand line options and/or config files settings may be provided by the application. These generally follow the conventions as described in "Application Options" below.

``` bash
$ R appr HelloThere --help
#> [TODO: help message]

$ R appr HelloThere "Stuart R. Jefferys"
#> Hello there, Stuart R. Jefferys.

$ R appr HelloThere --givenName "Stuart R." --familyName "Jefferys"
#> Hello there, Stuart R. Jefferys.

$ R appr HelloThere
# [TODO: error and help message]

$ echo "givenName = 'Stuart R.'" > "~/.appr/HelloThere.config"
$ echo "familyName = 'Jefferys'" > "~/.appr/HelloThere.config"

$ R appr HelloThere
#> Hello there, Stuart R. Jefferys.

$ R appr HelloThere --givenName "S. R."
#> Hello there, S. R. Jefferys.

$ R appr --noAppConfig HelloThere --givenName "S. R."
#> Hello there, S. R..
```

Application author
------------------

A author of an appr application has to install the appr package and create their application as a package. This is a normal R package with the following conventions:

The main script that runs the application is included as inst/rapp/<packagename>.R, usually this is very simple:

**inst/rapp/HelloThere.R**

        appObj <- appr::App( 'HelloThere.appr.desc.r', validate= TRUE )
        HelloThere::runApp( app )

Everything needed to run the app should be provided as functions in the normal way within file in the R/ directory. In addition there should be a `runApp` function definition there that when called runs the main application.

**R/run.R**

        runApp <- function( appObj ) {
            message( paste0( "Hello there, ", appObj["name"], "." ))
        } 

All the option parsing and parameter handling has been extracted out. The `appObj` contains the fully processed value for input, for use as is. The validation and processing is not gone, just pushed back into conversion functions called descriptor file. Much of the configuration of config file parameters and options is done by default:

-   All options are defined by the name that is used to access them within the program. This same name is the name used in any config file or on the command line. When used on the command line, the name must start with "--". The same option name means the same thing wherever used.
-   Option names must match the regexp \[A-Za-z\_\]\[A-Za-z\_0-9\]\*
-   Options always have a default value, although that can be NULL. This can be changed by specifying the option in a config file, as an environmental variable, or on the command line. Options either always take an explicit value, or never take a value (used as switches or counted flags)
    -   Switch options can be toggles, binary, trinary, or counted. Binary and toggle switch options have a TRUE or FALSE value by default, usually FALSE. Trinary options start with a NULL default. The presence of a toggle option switches the value. The presence of a binary or trinary option sets the value to a pre-specified value, usually TRUE. If a binary or trinary switch sets the value to FALSE, it is usually named something like no<switchOpt>. Often both <switchOpt> and no<switchOpt> binary options can be used, explicitly setting an option, even if it has a default. Syntax supports making this easy without requiring a merge function. Simialrly, trinary options add an "unset<switchOpt>" to explicitly set the option NULL, and also have supporting syntax.
    -   Counted options are treated like array options, with each presence of an option adding a TRUE, FALSE, or possibly NULL option, as configiured.
    -   If an option provides an explicit valuem it is always read as a string. A conversion function must be specified or provided \[Described below\] to validate, combine, and/or convert from the string value or values obtained from the operating system to whatever type of value the option provides in the program.
-   Options from command line are formatted by the OS, which determines how to split up option names and any values. Normally a space is used to separate them. The OS specifies what needs to be done to include special characters in values; generally you can use quoted strings or escape the character Of course, then you also have to escape quotes, and that escape charater in values too. The first layer of unescaped quotes is probably removed when passing to the program. But see your OS for details.
-   In the config file, the default separator between an option name and its value is an "=" sign. The default separator between one option (and possibly value) and the next is an end of line (any variation there-off). Any amount of spaces or tabs, including 0, may preceed the option, come immediately before or after the "=" sign, or separate the value from the EOL. To have values that contain spaces, tabs, or EOL characters, quote the values. Quotes inside values must be escaped. The first layer of unescaped quotes is removed when passing to the program.
-   Environmental variables may have types other than strings, but the value is always read as a string, hence "42" and 42 are the same value. It is converted back to a value if needed.
-   A short option name composed of one character may be defined as an alias for an option. Short options can only be used on the command line; they always starts with a single hyphen, "-". Short options may be bundled together after one hyphen. Only the last of a bundle of short options may take a value.
-   If the same option occurs multiple times, only the last one seen is recorded, unless the option is declared as an array value, or if duplicate option use is banned. CLI provided values are seen after config file values. Banned duplicates can affect just the config, just the cli, both, and can include environmental variable options.
-   If an option is declared as an array option, every use adds another value to the options array value, in the order seen. Array values are never NULL, they might be empty, and their values may be empty strings
-   Unknown option names are not allowed by default. It is possible to allow unspecified options if they are present in the config file. Options not specified and not in the config file are never allowed on the command line, and even if in the config file, parsing unknown options from the command line may be problematic. Only specified options can be set using environmental variables.
-   All unknown options and values, if allowed, are available in the application by name, or as a group of just the unknown options and values.

Values without option names are often allowed in command lines. These are called arguments or positional parameters. Given the above rules, it is not always obvious how to parse values on the command line without options. The following rules are used when parsing arguments on the command line.

-   If unknown options are not allowed on the command line, arguments are what is left after removing all options and values.
-   If unknown arguments are allowed, all known options are parsed from the command line first. If any single or double options remain, any preceeding other apparent options are removed and considered TRUE, unless they start with no or unset, in which case they are considered FALSE or NULL. This means an unspecified option that was supposed to be used like --ignoreOption "--delete" will actually be split into two options, as can't tell the value is not a following option. Any remaining options are assumed to have explicit values that follow. After those are removed, what remains are arguments. This can remove the first argument if it follows an unknow switch, so is not recommended.
-   The "--" option is special and indicates the end of named options and the begining of arguments. Normally this is turned on and can help with unknown option processing, but it can also cause problems if it needs to be used as an option value for some obscure reason, so this can be disabled.

Arguments are available within the program by position index. Expected arguments can also be defined to take a name, and if so that name can be used within the program. The array of the "rest" of the unknamed arguments can also be acessed if any are named.

### Option

An option is what a program will use internally to access a value. An option has the following properties: key: The name used to access the options value inside the application value: The value of the option default: The default value of the option if not otherwise set

**inst/rapp/HelloThere.appr.desc.r**

'opts' = \[ "fullName" = { arg=1, type= "string", desc= "The name of the person to say hello to.", doc= "This should be the full name as it is to be used in the greeting. If this is specified, also specifying familyName and/or --givenName options is an error." }, } name = { type = character dependsOn = \[1, "givenName", "familyName"\], validate &lt;- function() {

} }
