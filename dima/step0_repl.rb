def _read(str)
  str
end

def _eval(str)
  str
end

def _print(str)
  str
end

def _rep(str)
  _print(_eval(_read(str)))
end

while (print "user> "; line = gets())
  print _rep(line)
end

__END__

Add the 4 trivial functions READ, EVAL, PRINT, and rep (read-eval-print). READ, EVAL, and PRINT are basically just stubs that return their first parameter (a string if your target language is a statically typed) and rep calls them in order passing the return to the input of the next.

Add a main loop that repeatedly prints a prompt (needs to be "user> " for later tests to pass), gets a line of input from the user, calls rep with that line of input, and then prints out the result from rep. It should also exit when you send it an EOF (often Ctrl-D).

If you are using a compiled (ahead-of-time rather than just-in-time) language, then create a Makefile (or appropriate project definition file) in your directory.

It is time to run your first tests. This will check that your program does input and output in a way that can be captured by the test harness. Go to the top level and run the following:

make test^quux^step0
Add and then commit your new step0_repl.qx and Makefile to git.

Congratulations! You have just completed the first step of the make-a-lisp process.



