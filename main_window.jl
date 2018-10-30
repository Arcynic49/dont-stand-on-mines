using Gtk

mutable struct Minesquare
    row
    column
    mined::Bool
    flagged::Bool
    revealed::Bool
    neighborcount::Int
end

Minesquare() = Minesquare(1, 1, false, false, false, 0)
Minesquare(x, y) = Minesquare(x, y, false, false, false, 0)

mutable struct MineButton <: Gtk.GtkToggleButton
    handle::Ptr{Gtk.GObject}
    row
    column

    function MineButton(row, column)
        btn = GtkToggleButton()
        return Gtk.gobject_move_ref(new(btn.handle, row, column), btn)
    end
end

function seedfield!(array, minecount)
    while minecount > 0
        square = rand(array)
        if square.mined == false
            square.mined = true
            minecount -= 1
        end
    end
end

function getneighbors(array, row, column)
    neighbors = []
    for i=row-1:row+1
        for j=column-1:column+1
            if !((i == row) && (j == column))
                try
                    push!(neighbors, array[i,j])
                catch
                end
            end
        end
    end
    return neighbors
end

# Given an array with just mine flags set, update the neighbor counts
function setneighborcount!(array, square::Minesquare)
    square.neighborcount = 0
    neighbors = getneighbors(array, square.row, square.column)
    for neighbor in neighbors
        if neighbor.mined
            square.neighborcount += 1
        end
    end
end

# Make an array of Minesquares, mine it, then update neighbor counts
function makeminefield(numrows, numcolumns, nummines)
    mine_field  = [Minesquare(i, j) for i=1:numrows, j=1:numcolumns]
    seedfield!(mine_field, nummines)
    for tile in mine_field
        setneighborcount!(mine_field, tile)
    end
    return mine_field
end

# Main testing logic shoud go here
function on_button_clicked(widget, event)
    if event.button == 1
        mousebutton = "left"
    elseif event.button == 3
        mousebutton = "right"
    else
        mousebutton = "?"
    end

    println("Button $(widget.row), $(widget.column) has been $mousebutton clicked")
end

# This should be changed into a proper update function
# Revealed tiles, flagged, etc. Should account for failure states too.
function updatefield!(array, grid)
    maxrow, maxcolumn = size(array)
    for i=1:maxrow, j=1:maxcolumn
        tile = array[i, j]
        uitile = getindex(grid, j, i)
        if tile.mined
            set_gtk_property!(uitile, :label, "B")
        else
            set_gtk_property!(uitile, :label, tile.neighborcount)
        end
    end
end

minefield = makeminefield(16, 30, 99)

win = GtkWindow("Don't Stand on Mines", 400, 200)
grid = GtkGrid()
push!(win, grid)

maxrow, maxcolumn = size(minefield)
for i = 1:maxcolumn, j=1:maxrow
    b = MineButton(j, i)
    signal_connect(b, "button-release-event") do widget, event
        # on_button_clicked(widget, event)
        if event.button == 1
            mousebutton = "left"
            # If revealed make sure still toggled
            # If flagged make sure stays untoggled
            # If mined game over
            # Otherwise reveal self and set toggle
            # If self count = 0 reveal all unrevealed neighbors
        elseif event.button == 3
            mousebutton = "right"
            # If revealed do nothing
            # If flagged unflag
        else
            mousebutton = "?"
            # Middle mouse is "2"
            # Maybe use for revealed square with correct total flags
        end
        # Update the field
    end
    setindex!(grid, b, i, j)
end

updatefield!(minefield, grid)
showall(win)
