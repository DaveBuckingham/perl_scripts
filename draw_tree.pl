#!/usr/bin/perl -w
use strict;
use warnings;

#  (o_O)[._.]
#   ,|\_/| |\
#   / \  | |

#size of canvas. should be big enough for any graph but not too big (slow).
my $COLUMNS = 800;
my $ROWS    = 800;

#longer symbols will be cropped to this value
my $max_symbol_width;

#horizontal spacing of elements
my $HOR_SPACE = 6;

#counter for node names, only for TIKZ
my $nodeCount = 0;

#a canvas to draw the graph on
my @grid;

#initialize the canvas
sub clear_canvas{
    for (my $i = 0; $i <= $ROWS; $i++) {
       for (my $j = 0; $j <= $COLUMNS; $j++) {
	  $grid[$i][$j] = " ";
       }
    }
}

#used in setPositions() to track available position on each row
#not sure about magic number 30. . .
my @nextPos;
for (my $i = 0; $i < 30; $i++) {
   $nextPos[$i] = 1;
}

#this is not used by program. useful for debugging.
sub printTree {
   my $tree = $_[0];
   print("(" . $tree->{'val'});
   #print($tree->{'val'} . " :  " . $tree->{'x'} . "\n");
   foreach my $subtree (@{$tree->{'args'}}) {
      printTree($subtree);
   }
   print(") ");
}

#this is not used
sub getTreeDepth {
   my $tree = $_[0];
   my $maxChildDepth = 0;
   my $subtree;
   foreach $subtree (@{$tree->{'args'}}) {
      my $childDepth = getTreeDepth($subtree);
      if ($childDepth > $maxChildDepth) {
	 $maxChildDepth = $childDepth;
      }
   }
   return ($maxChildDepth + 1);
}

#parse a string into a tree (hash of references to hashes);
sub parseString {
   my $line = $_[0];
   chomp($line);
   my $recDepth = $_[1];
   if ($recDepth > 50) {
      die("recursion limit\n");
   }
   my %parent;
   #add spaces around the parens
   $line =~ s/([()])/ $1 /g;
   #remove any spaces at the start of the string.
   $line =~ s/^\s*//g;
   #remove any multiple spaces.
   $line =~ s/\s+/ /g;
   #split the string into an array.
   my @symbols = split(' ', $line);
   my $symbol = shift(@symbols);
   #a node must begin with an open paren.
   if ($symbol ne "(") {
      die("missing open paren!\n");
   }
   $parent{'val'} = shift(@symbols);
   #every node needs a value.
   unless(defined($parent{'val'})) {
      die("node missing value.\n");
   }
   if (length($parent{'val'}) > $max_symbol_width) {
      $parent{'val'} = substr($parent{'val'}, 0, $max_symbol_width);
   }
   $parent{'args'} = [];
   $parent{'x'} = 0;
   #until we reach the closing paren that matches the first opening paren. . .
   while (defined($symbol = shift(@symbols)) && $symbol ne ")") {

      my $substring;
      #if we find an open paren, cons symbols until we reach the matching closing paren, and recurse on result
      if ($symbol eq "(") {
	 $substring = ($symbol . " ");
	 my $openParens = 1;
	 while ($openParens > 0) {
	   my $subSymbol = shift(@symbols);
	   if ($subSymbol eq "(") {
	      $openParens++;
	   }
	   elsif ($subSymbol eq ")") {
	      $openParens--;
	   }
	   $substring .= ($subSymbol . " ");
	 }
      }
      #not an open paren, so must be a node value
      else {
	 $substring = "( $symbol )";
      }
      push(@{$parent{'args'}}, parseString($substring, $recDepth));
   }
   #make sure we ended with a close paren.
   unless (defined($symbol) && $symbol eq ")") {
      die("missing close paren!\n");
   }
   return \%parent;
}

#too lazy to comment much after this point. . .

#main drawing algorithm. assign positions to nodes.
sub setPositions {
   my ($tree, $depth, $shift) = @_; #depth = h
   my $place;

   if ($shift > 0) {
      $tree->{'x'} += $shift;
      $nextPos[$depth] = $tree->{'x'} + 2;
      foreach my $child (@{$tree->{'args'}}) {
	 setPositions($child, $depth + 1, $shift);
      }
      return;
   }

   if(@{$tree->{'args'}} == 0) {
      $place = $nextPos[$depth] + $shift;
   }
   else {
      my $sumChildPlace = 0;
      foreach my $child (@{$tree->{'args'}}) {
         setPositions($child, $depth + 1, $shift);
	 $sumChildPlace += $child->{'x'};
      }
      my $count = @{$tree->{'args'}};
      $place = (int($sumChildPlace / $count) + $shift);
   }
   if ($place >= $nextPos[$depth]) {
      $tree->{'x'} = $place;
   }
   else {
      foreach my $child (@{$tree->{'args'}}) {
	 #setPositions($child, $depth + 1, $nextPos[$depth]);
	 setPositions($child, $depth + 1, $nextPos[$depth] - $place);
      }
      $tree->{'x'} = $nextPos[$depth];
   }
   $nextPos[$depth] = $tree->{'x'} + 2;
}


#draw the tree on the canvas.
sub drawTree {
    my $tree = $_[0];
    my $row = $_[1];
    my $x = $tree->{'x'} * $HOR_SPACE;
    my @label = split('', "(" . $tree->{'val'} . ")");
    splice(@{$grid[$row]}, $x - (@label / 2) + 1, @label, @label);
    foreach my $subtree (@{$tree->{'args'}}) {
        drawTree($subtree, $row + 3);
        my $cx = $subtree->{'x'} * $HOR_SPACE;
        if ($cx < $x) {
	    $grid[$row + 1][$x - 2] = "/";
	    $grid[$row + 2][$cx + 1] = "/";
	    for (my $i = $cx + 2; $i < $x - 2; $i++) {
		$grid[$row + 1][$i] = "_";
	    }
	}
      elsif ($cx > $x) {
	 $grid[$row + 1][$x + 2] = "\\";
	 $grid[$row + 2][$cx - 1] = "\\";
	 for (my $i = $x + 3; $i < $cx - 1; $i++) {
	    $grid[$row + 1][$i] = "_";
	 }
      }
      else {
	 $grid[$row + 1][$x] = "|";
	 $grid[$row + 2][$x] = "|";
      }
   }
   return \@grid;
}

sub initTikz {

print(
q{\begin{tikzpicture}[scale=1]
    tikzstyle{every node}=[draw=none, fill=none];
});

}



sub generateTikz {
    my $tree = $_[0];
    my $y = $_[1];
    my $x = $tree->{'x'};
    my $label = $tree->{'val'};
    if ($label eq "-") {
        $label = "--";
    }
    if (length($label) == 1 || $label eq "--") {
        $label = "\\large $label";
    }
    my $nodeId = $nodeCount++;
    print("    \\path($x, $y) node (v$nodeId) {\\textit{$label}};\n");
    my $subNodeCount = 1;
    foreach my $subtree (@{$tree->{'args'}}) {
	my $cx = $subtree->{'x'} * $HOR_SPACE;
	my $cy = $y - 1;
	my $subNodeId = generateTikz($subtree, $cy);
	print("    \\draw (v$nodeId) -- (v$subNodeId);\n");
    }
    return $nodeId;
}

sub closeTikz {
    print("\\end{tikzpicture}\n");
}


#print out the canvas.
sub printCanvas {
   my $space = 8;
   my $minStart = 0;
   my $colIndex = 0;

   while ($minStart == 0) {
      for (my $r = 0; $r <= $ROWS; $r++) { #for each row
	 if ($grid[$r][$colIndex] ne " ") {
	    $minStart = $colIndex;
	 }
      }
      $colIndex++;
   }

    for (my $i = 0; $i <= $ROWS; $i++) {
	my $line = join('', @{$grid[$i]});
	unless ($line =~ /^ *$/) {
	    $line =~ s/\s*$//g;
	    $line = substr($line, $minStart);
	    print($line);
	    print("\n");
	}
    }
    print("\n");
}

#here's our "main" program body:
my $make_tikz = 0;
my $print_equation = 0;
foreach my $arg (@ARGV) {
    if ($arg eq "-t") {
	$make_tikz = 1;
    }
    if ($arg eq "-e") {
	$print_equation = 1;
    }
}


while (my $stringTree = <STDIN>) {
    chomp($stringTree);
    $stringTree =~  s/   TREE:  //;
    $max_symbol_width = $make_tikz ? 5 : 8;
    my $tree = parseString($stringTree, 0);
    setPositions($tree, 0, 0);
    if ($make_tikz) {
	initTikz();
	generateTikz($tree, 0);
	closeTikz();
    }
    else {
	clear_canvas();
	drawTree($tree, 0);
	printCanvas();
    }
}
