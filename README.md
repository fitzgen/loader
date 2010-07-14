# `$loader`

Speed up your pages by transforming

    <script src="jquery.min.js" type="text/javascript"></script>
    <script src="jquery.tempest.js" type="text/javascript"></script>
    <script src="jquery.lightbox.js" type="text/javascript"></script>
    <script src="jquery.autocomplete.js" type="text/javascript"></script>
    <script src="wu.js" type="text/javascript"></script>
    <script type="text/javascript">
        $(document).read(function () {
            doSomeStuff();
            // ...
        });
    </script>

in to

    <script src="loader.js" type="text/javascript"></script>
    <script type="text/javascript">

        // jQuery and Wu are loaded in parallel.

        $loader.load(["jquery.min.js", "wu.js"])

               // The jQuery plugins are loaded in parallel as well, but only after
               // jQuery is already loaded and evaluated.

               .load(["jquery.tempest.js", "jquery.lightbox.js", "jquery.autocomplete.js"],
                     function () {
                         doSomeStuff();
                         // ...
                     });

    </script>

## Getting up and running

`$loader` is written in [ParenScript][] (a small, Lispy language that compiles
to Javascript), to build the latest source, you will need a Common Lisp
implementation (my build script targets [Steel Bank Common Lisp][]) and
ParenScript. Then just run

    ./build

If you just want to get up and running quickly, I will put prebuilt, minified
versions up on the GitHub [downloads page][] as soon as there is some stability.

[ParenScript]: http://common-lisp.net/project/parenscript/
[Steel Bank Common Lisp]: http://sbcl.sourceforge.net/
[downloads page]: http://github.com/fitzgen/loader/downloads