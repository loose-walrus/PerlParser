#!/usr/bin/perl

open (INF, "<", $ARGV[0]) or die "couldn't open sourcecode\n";

# these lines of code slurp the whole file into one scalar $in_buffer
{
	local $/;
	$remainText = <INF>;
}

#$remainText = $inBuffer;
$nextToken = "";

&lex();
&program();
print $remainText;
print "Your program is syntactically correct.\n";

#$count = 0;
sub lex()
{
	print " nexttoken was: " . $nextToken . "\n";
	if ($remainText =~ m/^(\s)*(program|begin|\;|end|\:\=|read|\(|\,|\)|write|if|then|else|while|do|\+|\-|\*|\/|\=|\<\>|\<\=|\<|\>\=|\>)/ ) #checks for terminals and if matched stores the matched terminal into nextToken
	{
		$nextToken = $2;
		$remainText = $';
	}
	elsif ($remainText =~ m/^(\s)*$/ ) #checks for whitespace at ending and if it matches nextToken is assigned the empty string
	{
		$nextToken = "";
	}
	elsif ($remainText =~ m/^(\s)*([0-9]+)/ ) #checks for digits and if it matches nextToken is assigned CONSTANT
	{
		$nextToken = "CONSTANT";
		$remainText = $';
	}
	elsif ($remainText =~ m/^(\s)*([A-Z]([A-Za-z]|[0-9])*)/ ) #checks for a possible program name and if it matches nextToken is assigned PROGNAME
	{
		$nextToken = "PROGNAME";
		$remainText = $';
	}
	elsif ($remainText =~ m/^(\s)*([a-z]([a-z]|[0-9])*)/i ) #checks for a possible variable name and if it matches nextToken is assigned VARIABLE
	{
		$nextToken = "VARIABLE";
		$remainText = $';
	}
	else
	{
		$nextToken = $remainText;
		die;
	}
	print " nexttoken is: " . $nextToken . "\n";
}


#  <program> ::= program <progname> <compound stmt>
#$count2 = 0;
sub program()
{
	$eMatch="program";
	if($nextToken eq $eMatch)
	{
		&lex();
		local $eMatch="PROGNAME";
		if($nextToken eq $eMatch){
			&lex();
			local $eMatch="begin";
			if($nextToken eq $eMatch) #checks for a begin as that is the start of a compound_statement
			{
				&lex(); #lex is called here because the check for the begin isn’t done in compound_statement
				&compound_stmt();
			}else{
				&error($eMatch);
			}
		}else{
			&error($eMatch);
		}
	}else{
		&error($eMatch);
	}
}

#  <compound stmt> ::= begin <stmt> {; <stmt>} end
#$count3 = 0;
sub compound_stmt()
{
	&stmt();
	%matchHash = (";" => \&stmt,"end" => \&nothing); #each possible match is linked to a reference of the sub it will call if found in a hash table
	$eMatch=";";
	$eMatch2="end";
	while($nextToken eq ";")
	{
		print " 000000000matched: " . $nextToken . " \n ";
		&lex();
		&stmt();

 		print " 000000000out " .   " \n ";
	}
	print $nextToken . "———" . "\n ";
	if($nextToken eq "end")
	{
		&lex();
	}else{
		&error("; || end");
	}
}

sub nothing()
{
	print "nothing called\n";
}

#  <stmt> ::=  <assignment stmt> | <read stmt> | <write stmt> | <structured stmt>
#$count5 = 0;
sub stmt()
{
	%matchHash = ("read" => \&read_stmt,"write" => \&write_stmt,"if" => \&if_stmt,"while" => \&while_stmt,"begin" => \&compound_stmt,"+" => \&expression,"-" => \&expression,"VARIABLE" => \&assignment_stmt,"PROGNAME" => \&assignment_stmt,"CONSTANT" => \&expression,"(" => \&expressionparen); #each possible match is linked to a reference of the sub it will call if found in a hash table
	if(exists $matchHash{$nextToken})
	{
		$temp = $nextToken; #stores match
		&lex();
		&{$matchHash{$temp}}; #calls function associated with match
	}else{
		&error(" read || write || if || while || begin || +| | - || VARIABLE || CONSTANT || ( ");
	}
}

#lexpression calls <lex> and then <expression>
#$count6 = 0;
sub lexpression()
{
	&lex();
	&expression();
}

#  <simple stmt> ::= <assignment stmt> | <read stmt> | <write stmt> #no need as only called by stmt, and checks are done in stmt.
#  <assignment stmt> ::= <variable> := <expression>
#$count7 = 0;
sub assignment_stmt()
{
	$eMatch = ":=";
	if($nextToken eq $eMatch)
	{
		&lexpression();
	}else{
		&error($eMatch);
	}
}

#  <read stmt> ::= read ( <variable> { , <variable> } )
$count8 = 0;
sub read_stmt()
{
	$eMatch="(";
	if($nextToken eq $eMatch)
	{
		&lex();
		local $eMatch="VARIABLE";
		if($nextToken eq $eMatch  | $nextToken eq "PROGNAME")
		{
			&lex();
			%matchHash = ("," => \&lexvar,")" => \&lexbreak); #each possible match is linked to a reference of the sub it will call if found in a hash table
			while(true)
			{
				if(exists $matchHash{$nextToken})
				{
					&{$matchHash{$nextToken}}; #calls function associated with match
				}else{
					&error(" , ||  ) ");
				}
			}
		}else{
			&error($eMatch);
		}

	}else{
		&error($eMatch);
	}
}

#lexbreak calls lex and breaks out of a loop (has to be called from inside a loop)
#$count9 = 0;
sub lexbreak()
{
	&lex();
	last;
}


#lexvar calls lex and then checks if $nextToken is a VARIABLE
#$count10 = 0;
sub lexvar()
{
	&lex();
	$eMatch="VARIABLE";
	if($nextToken eq $eMatch  | $nextToken eq "PROGNAME")
	{
		&lex();
	}else{
		&error($eMatch);
	}
}

#  <write stmt> ::= write ( <expression> { , <expression> } )
#$count11 = 0;
sub write_stmt()
{
	$eMatch="(";
	if($nextToken eq $eMatch)
	{
		&lex();
		%matchHash = ("+" => \&expression,"-" => \&expression,"VARIABLE" => \&expression, "PROGNAME" => \&expression, "CONSTANT" => \&expression,"(" => \&lexpressionparen); #each possible match is linked to a reference of the sub it will call if found in a hash table

		if(exists $matchHash{$nextToken})
		{
			&{$matchHash{$nextToken}};
			while($nextToken eq ",")	#keeps checking for commas and calling lex & expression to write all the different expressions, until no more commas are found
			{
				&lexpression;
			}
			$eMatch= ")";
			if($nextToken eq $eMatch)# checks fro the closing paren
			{
				&lex();
			}else{
				&error($eMatch);
			}
		}
	}else{
		&error($eMatch);
	}
}


#  <structured stmt> ::= <compound stmt> | <if stmt> | <while stmt> # NO NEED: only called by <stmt>, checks done there
#  <if stmt> ::= if <expression> then <stmt> |
#                if <expression> then <stmt> else <stmt>
#$count12 = 0;
sub if_stmt()
{
	&expression();
	local $eMatch = "then";
	if($nextToken eq $eMatch)
	{
		print "THEN FOUND\n"
		&lex();
		&stmt();
		local $eMatch = "else";
		if($nextToken eq $eMatch) #checks for else and if found calls lex and stmt or if not does nothing, as that means the if statement takes on the first possible for
		{
			&lex();
			&stmt();
		}
	}else{
		&error($eMatch);
	}
}

#  <while stmt> ::= while <expression> do <stmt>
sub while_stmt()
{
	&lex();
	&expression();
	$eMatch = "do";
	if($nextToken eq $eMatch)
	{
		&lex();
		&stmt();
	}else{
		&error($eMatch);
	}

}

#  <expression> ::=  <simple expr> |
#                    <simple expr> <relational_operator> <simple expr>
#$count13 = 0;
sub expression()
{
	&simple_expr();

	%matchHash = ("=" => \&simple_expr,"<>" => \&simple_expr,">=" => \&simple_expr, "<="  => \&simple_expr,  ">" => \&simple_expr ,"<" => \&simple_expr);#each possible match is linked to a reference of the sub it will call if found in a hash table

	if(exists $matchHash{$nextToken})
	{
		$temp = $nextToken;#stores match
		&lex();
		&{$matchHash{$temp}};#calls function associated with match
 }
}

#  <simple expr> ::= [ <sign> ] <term> { <adding_operator> <term> }
#$count14 = 0;
sub simple_expr()
{
	if($nextToken eq "+" | $nextToken eq "-")
	{
		&lex();
	}
	&term();
	while($nextToken eq "+" |$nextToken eq "-" )
	{
		&lex();
		&term();
	}
}

#lexterm calls lex and then term
sub lexterm()
{
	&lex();
	&term();
}

#  <term> ::= <factor> { <multiplying_operator> <factor> }
#$count15 = 0;
sub term()
{
	&factor();
	while($nextToken eq "*" |$nextToken eq "/")
	{
		&lex();
		&factor();
	}
}

#  <factor> ::= <variable> | <constant> | ( <expression> )
#$count16 = 0;
sub factor()
{
	%matchHash = ("VARIABLE" => \&lex, "PROGNAME" => \&lex, "CONSTANT" => \&lex, "(" => \&lexpressionparen);  #each possible match is linked to a reference of the sub it will call if found in a hash table

	if(exists $matchHash{$nextToken})
	{
		&{$matchHash{$nextToken}}; #calls function associated with match
	}else{
		&error(" VARIABLE || CONSTANT || ( ");
	}
}

#calls lex and then expressionparen
sub lexpressionparen()
{
	&lex();
	&expressionparen();
}

# expressionparen() checks for another "(" and either calls itself or  calls lexpression() and then checks for a closing paren
#$count17 = 0;
sub expressionparen()
{
	if($nextToken eq "(") #checks for possible nested parens, and calls itself if found. e.g. (((-1)+ (-2))+(-3)))
	{
		&lex();
		&expressionparen();
	}else{
		&expression();
		$eMatch = ")";
		if($nextToken eq $eMatch) #checks for the closing paren
		{
			&lex();
		}else{
			&error($eMatch);
		}
	}
}

sub error
{
	print "Error called \n";
	print " Expecting <" . $_[0] . "> was <" . $nextToken . ">\n" . " Remaining program:" . $remainText . "\n";
	die;
}
