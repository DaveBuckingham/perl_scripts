#!/usr/bin/perl
use strict;
use warnings;
use List::Util qw( shuffle sum);

my $NONE = 0;
my $BRANCH = 1;
my $ISLAND = 2;

my $START_BRANCHES = int(rand(10)) + 1;
my $START_ISLANDS = int(rand(4));
my $NEW_BRANCH_PROB = .01;
my $NEW_ISLAND_PROB = .005;

#my $num_rows = 41;
#my $num_cols = 69;
my $num_rows = 20;
my $num_cols = 20;


my @grid;  # matrix representing maze. 1 == wall, 0 == corridor

my @heads;  # walls that are currently growing

# is there enough space around a cell for it to start a new branch or island?
sub room {
    my $row = $_[0];
    my $col = $_[1];
    my $cell = $grid[$row][$col];
    my $up_left = $grid[$row-1][$col-1];
    my $up = $grid[$row-1][$col];
    my $up_right = $grid[$row-1][$col+1];
    my $right = $grid[$row][$col+1];
    my $down_right = $grid[$row+1][$col+1];
    my $down = $grid[$row+1][$col];
    my $down_left = $grid[$row+1][$col-1];
    my $left = $grid[$row][$col-1];

    if ($cell || ($row == 0) || ($row == $num_rows - 1) || ($col == 0) || ($col == $num_cols - 1)) {
	return $NONE;
    }
    elsif (!($up_left + $up + $up_right + $right + $down_right + $down + $down_left + $left)) {
        return $ISLAND;
    }
    elsif ( ($left && !($up || $up_right || $right || $down_right || $down)) ||
            ($right && !($up || $up_left || $left || $down_left || $down)) ||
            ($up && !($left || $down_left || $down || $down_right || $right)) ||
            ($down && !($left || $up_left || $up || $up_right || $right))) {
	return $BRANCH;
    }
    else {
        return $NONE;
    }
}

# move heads along, growing wall. return 0 if no heads can move, otherwise, return 1.
sub grow {
    my $row;
    my $col;
    my $success = 0;
    my $is_room;
    for (my $i = 0; $i < @heads; $i++) {
	my @order = shuffle([-1, 0], [1, 0], [0, -1], [0, 1]);

	do {
	    my @direction = @{shift(@order)};
	    ($row, $col) = ($heads[$i][0] + $direction[0], $heads[$i][1] + $direction[1]);
	    $is_room = room($row, $col);
	}
	while (@order && !$is_room);
        if ($is_room) {
	    $grid[$row][$col] = 1;
	    $heads[$i] = [$row, $col];
	    $success = 1;
	}
    }
    return $success;
}

# create a new head. argument is either "$ISLAND" or "$BRANCH". return 1 if success, 0 if failure
sub make_branch {
    my @legal;
    my $row;
    my $col;
    for ($row = 0; $row < $num_rows; $row++) {
	for ($col = 0; $col < $num_cols; $col++) {
	    if (room($row, $col) == $_[0]) {
	        push(@legal, [$row, $col]);
	    }
	}
    }
    if (@legal == 0) {
	return 0;
    }
    ($row, $col) = @{$legal[rand @legal]};
    push(@heads, [$row, $col]);
    $grid[$row][$col] = 1;
    return 1;
}

# check if adjacent cells are walls
sub above {
    return ($_[0] > 0 and $grid[$_[0]-1][$_[1]]);
}
sub below {
    return (($_[0] < $num_rows - 1) and $grid[$_[0]+1][$_[1]]);
}
sub left {
    return (($_[1] > 0) and $grid[$_[0]][$_[1]-1]);
}
sub right {
    return (($_[1] < $num_cols - 1) and $grid[$_[0]][$_[1]+1]);
}



# print the maze. cells are two characters wide and one character tall
sub simple_print {
    for (my $row = 0; $row < $num_rows; $row++) {
	for (my $col = 0; $col < $num_cols; $col++) {
	    my @cell = ($row, $col);
	    if (!$grid[$row][$col]) {
		print "  ";
	    }
	    elsif ((left(@cell) || right(@cell)) && !(above(@cell) || below(@cell))) {
		print "==";
	    }
	    elsif ((above(@cell) || below(@cell)) && !(left(@cell) || right(@cell))) {
		print "||";
	    }
	    else {
		print "==";
	    }
	}
	print "\n";
    }
}

# print the maze. cells are three characters wide and two characters tall
sub pretty_print {
    my $row;
    my $col;
    for ($row = 0; $row < $num_rows; $row++) {
	for ($col = 0; $col < $num_cols; $col++) {
	    my ($left,$right,$above) = (left($row, $col), right($row, $col), above($row, $col));

	    if (!$grid[$row][$col]) {
		print "   ";
	    }
	    else {
		print($left ? "_" : " ");
		print($above ? "|" : ($left || $right) ? "_" : "|");
		print($right ? "_" : " ");
	    }
	}
	print "\n";
	for ($col = 0; $col < $num_cols; $col++) {
	    if ($grid[$row][$col] && below($row, $col)) {
		print " | ";
	    }
	    else {
		print "   ";
	    }
	}
	print "\n";
    }
}

# initialize grid
for (my $row = 0; $row < $num_rows; $row++) {
    for (my $col = 0; $col < $num_cols; $col++) {
        if ($row==0 || $col==0 || $row==($num_rows - 1) || $col==($num_cols - 1)) {
	    $grid[$row][$col] = 1;
	}
	else {
	    $grid[$row][$col] = 0;
	}
    }
}
$grid[0][2] = 0;
$grid[$num_rows - 1][$num_cols - 3] = 0;

# make starting heads
for (my $i=0; $i < $START_BRANCHES; $i++) {
    make_branch($BRANCH);
}
for (my $i=0; $i < $START_ISLANDS; $i++) {
    make_branch($ISLAND);
}

# main loop
while(grow || make_branch($BRANCH)){
    if (rand() < $NEW_ISLAND_PROB) {
	make_branch($ISLAND);
    }
    if (rand() < $NEW_BRANCH_PROB) {
	make_branch($BRANCH);
    }
};

# print maze
#simple_print;
pretty_print;

