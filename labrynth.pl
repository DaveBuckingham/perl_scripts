#!/usr/bin/perl
use strict;
use warnings;
use List::Util qw( shuffle sum);


#  _________________________________________________________________________
# |                                                                         |
# |                         DAVE'S LABRYNTHS OF PERL                        |
# |                                                                         |
# | provide up to 3 optional command-line parameters: width, height, seed   |
# | e.g. :                                                       __   ______|________
# | # labrynth.pl 25 25 1337                                    |  |_____    _____   |
# |                                                           __|   __|   __|__    __|
# |__________________________________________________________|__   _________   |___  |________
#						          |   __|      __|  |__   |   __|   __|  
#						          |_____   |  |  |  |   __|  |   __   |  
#								|__|__   |  |  |  |__   |     |  
#								|_____   |__    __   |  |__|  |  
#								|__   |        |   ________   |  
#								|  |__   \oO/   __    _____|__|  
#								|         ][      |  |_____   |  
#								|  |  |  |  |  |  |__    __   |  
#								|__|  |__|__|  |__|  |__|  |  |  
#								|________|________|________   | 
 

# +------------------------------------+
# |      OPTIONAL USER PARAMETERS      |
# +------------------------------------+
my $width = (@ARGV > 0) ? $ARGV[0] : 30;
my $height = (@ARGV > 1) ? $ARGV[1] : 30;
my $seed = (@ARGV > 2) ? $ARGV[2] : int(rand(1000000));
my $num_rows = $height + 1;
my $num_cols = $width + 1;;
srand($seed);


# +------------------------------------+
# |      OPTIONAL USER PARAMETERS      |
# +------------------------------------+

## BRANCH AND ISLAND PARAMETERS
my $START_BRANCHES = int(rand(20)) + 5;
my $START_ISLANDS = int(rand(4));
my $NEW_BRANCH_PROB = .05;
my $NEW_ISLAND_PROB = .005;

## ENUMERATE ARGUMENTS TO MAKE_BRANCH()
my $NONE = 0;
my $BRANCH = 1;
my $ISLAND = 2;

## ENUMERATE SIDES OF A CELL
my $WALL = 1;
my $BASE = 2;

## ENUMERATE DIRECTION A HEAD MAY BE FACING, ARGUMENT TO ROOM()
my $OUT = 0;
my $IN = 1;
my $BOTH = 2;


# +------------------------------------+
# |          GLOBAL VARIABLES          |
# +------------------------------------+
my @grid;  # matrix of cells
my @heads;  # walls that are currently growing


# +------------------------------------+
# |            ROOM()                  |
# +------------------------------------+
# is there enough space around a wall for it to start a new branch or island?
sub room {
    my $row = $_[0];
    my $col = $_[1];
    my $side = $_[2];
    my $direction = $_[3];
    my $in_clear;
    my $out_clear;

    if (($row < 0) || ($row >= $num_rows) || ($col < 0) || ($col >= $num_cols) || ($grid[$row][$col] & $side) ) {
	return $NONE;
    }

    if ($side == $WALL) {
	$in_clear = !( (($col == $num_cols - 1) || ($grid[$row][$col] & $BASE)) ||
	               (($col == 0) || ($grid[$row][$col-1] & $BASE)) ||
		       (($row == $num_rows - 1) || ($grid[$row+1][$col] & $WALL)) );

	$out_clear = !( (($row == 0) || ($grid[$row-1][$col] & ($BASE | $WALL))) ||
	                (($row == 0) || ($col > 0) && ($grid[$row-1][$col-1] & $BASE)) );
    }
    else {  ## $side == $BASE
	$in_clear = !( ($grid[$row][$col] & $WALL) ||
	               (($col == 0) || ($grid[$row][$col-1] & $BASE)) ||
		       (($row == $num_rows - 1) || ($grid[$row+1][$col] & $WALL)) );

	$out_clear = !( (($col == $num_cols - 1) || ($grid[$row][$col+1] & ($BASE | $WALL))) ||
	                (($row == $num_rows - 1) || ($col < $num_cols - 1) && ($grid[$row+1][$col+1] & $WALL)) );
    }

    if ($direction == $BOTH) {
	return ($in_clear && $out_clear);
    }
    elsif ($direction == $IN) {
	return ($in_clear && !$out_clear);
    }
    else {  ## $DIRECTION == $OUT
	return ($out_clear && !$in_clear);
    }
}

# +------------------------------------+
# |              GROW()                |
# +------------------------------------+
# move heads along, growing wall. if no heads can move, return 0 and empty heads list. otherwise, return 1.
sub grow {
    my $row;
    my $col;
    my $side;
    my $direction;
    my $success = 0;
    for (my $i = 0; $i < @heads; $i++) {
	my $is_room = 0;
	my @choices;
	($row, $col, $side, $direction) = @{$heads[$i]};
	if (($side == $WALL) && ($direction == $OUT)) {
	    push(@choices, [$row-1, $col-1, $BASE, $IN]);
	    push(@choices, [$row-1, $col, $WALL, $OUT]);
	    push(@choices, [$row-1, $col, $BASE, $OUT]);
	}
	elsif (($side == $WALL) && ($direction == $IN)) {
	    push(@choices, [$row, $col-1, $BASE, $IN]);
	    push(@choices, [$row+1, $col, $WALL, $IN]);
	    push(@choices, [$row, $col, $BASE, $OUT]);
	}
	elsif (($side == $BASE) && ($direction == $OUT)) {
	    push(@choices, [$row, $col+1, $WALL, $OUT]);
	    push(@choices, [$row, $col+1, $BASE, $OUT]);
	    push(@choices, [$row+1, $col+1, $WALL, $IN]);
	}
	elsif (($side == $BASE) && ($direction == $IN)) {
	    push(@choices, [$row+1, $col, $WALL, $IN]);
	    push(@choices, [$row, $col-1, $BASE, $IN]);
	    push(@choices, [$row, $col, $WALL, $OUT]);
	}
	
	@choices = shuffle(@choices);  ## randomize weather to go straight, turn left, or right

	while (@choices && !$is_room) {
	    my @choice = @{shift(@choices)};
	    $is_room = room(@choice);
	    if ($is_room) {
		$grid[$choice[0]][$choice[1]] |= $choice[2];
		$heads[$i] = \@choice;
		$success = 1;
	    }
	}
    }
    if (!$success) {
	@heads = ();
    }
    return $success;
}


# +------------------------------------+
# |           MAKE_BRANCH()            |
# +------------------------------------+
# create a new head. argument is either "$ISLAND" or "$BRANCH". return 1 if success, 0 if failure
sub make_branch {
    my @legal;
    my $row;
    my $col;
    my $side;
    my $direction;
    for ($row = 0; $row < $num_rows; $row++) {
	for ($col = 0; $col < $num_cols; $col++) {
	    foreach $side ($WALL, $BASE) {
		if ($_[0] == $ISLAND) {
		    if (room($row, $col, $side, $BOTH)) {
			$direction = rand() < .5 ? $IN : $OUT;
			push(@legal, [$row, $col, $side, $direction]);
		    }
		}
		else {
		    for $direction ($OUT, $IN) {
			if (room($row, $col, $side, $direction)) {
			    push(@legal, [$row, $col, $side, $direction]);
			}
		    }
		}
	    }
	}
    }
    if (@legal == 0) {
	return 0;
    }
    ($row, $col, $side, $direction) = @{$legal[rand @legal]};
    push(@heads, [$row, $col, $side, $direction]);
    $grid[$row][$col] |= $side;
    return 1;
}


# +------------------------------------+
# |           PRINT_MAZE()             |
# +------------------------------------+
sub print_maze {
    for (my $row = 0; $row < $num_rows; $row++) {
	for (my $col = 0; $col < $num_cols; $col++) {
	    my $cell = $grid[$row][$col];
	    if ($grid[$row][$col] & $WALL) {
		print "|";
	    }
	    elsif (($grid[$row][$col] & $BASE) && ($col > 0) && ($grid[$row][$col-1] & $BASE)) { 
		print "_";
	    }
	    else {
		print " ";
	    }
	    if ($grid[$row][$col] & $BASE) {
		print "__";
	    }
	    else {
		print "  ";
	    }
	}
	print "\n";
    }
}


# +------------------------------------+
# |          INITIALIZE GRID           |
# +------------------------------------+
for (my $row = 0; $row < $num_rows; $row++) {
    for (my $col = 0; $col < $num_cols; $col++) {
	$grid[$row][$col] = 0;
        if (($row==0 || $row==($num_rows - 1)) && ($col < ($num_cols - 1))) {
	    $grid[$row][$col] |= $BASE;
	}
        if (($col==0 || $col==($num_cols - 1)) && ($row > 0)) {
	    $grid[$row][$col] |= $WALL;
	}
    }
}
$grid[0][0] = 0;
$grid[$num_rows - 1][$num_cols - 2] = 0;


# +------------------------------------+
# |       MAKE INITIAL HEADS           |
# +------------------------------------+
for (my $i=0; $i < $START_BRANCHES; $i++) {
    make_branch($BRANCH);
}
for (my $i=0; $i < $START_ISLANDS; $i++) {
    make_branch($ISLAND);
}


# +------------------------------------+
# |            MAIN LOOP               |
# +------------------------------------+
while(grow || make_branch($BRANCH)){
    if (rand() < $NEW_ISLAND_PROB) {
	make_branch($ISLAND);
    }
    if (rand() < $NEW_BRANCH_PROB) {
	make_branch($BRANCH);
    }
};


# +------------------------------------+
# |          OUTPUT RESULTS            |
# +------------------------------------+
print_maze;
#print("width: $width   height: $height   seed: $seed\n");
