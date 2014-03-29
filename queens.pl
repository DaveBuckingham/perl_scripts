#!/usr/bin/perl -w
use strict;
use warnings;

###########################################
#                                         #
#                 QUEENS                  #
#                                         #
###########################################

my @board = (0, -1, -1, -1, -1, -1, -1, -1);
my $column = 1;

while ($column >= 0) {
    $board[$column]++;
    my $safe = 1;

    if ($board[$column] > 7) {
	$board[$column--] = -1;
	$safe = 0;
    }

    my $compare = $column - 1;
    while ($safe && ($compare >= 0)) { 
	if (($board[$column] == $board[$compare]) ||
	   (($column - $compare) == abs($board[$column] - $board[$compare]))) {
	    $safe = 0;
	}
	$compare--;
    }

    if ($safe) {
	if ($column == 7) {
	    #print "@board\n";

 	    printf("_________________________________\n");
 	    my $row;
 	    my $col;
 	    for ($row = 0; $row < 8; $row++) {
 		for ($col = 0; $col < 8; $col++) {
 		    printf("|%s", $board[$col] == $row ? " @ " : (($row + $col + 1) % 2) ? "   " : ".-,");
 		}
 		printf("|\n");
 		for ($col = 0; $col < 8; $col++) {
 		    printf("|%s", $board[$col] == $row ? "{_}" : "___");
 		}
 		printf("|\n");
 	    }
 	    printf("\n");

	}
	else {
	    $column++;
	}
    }
}

