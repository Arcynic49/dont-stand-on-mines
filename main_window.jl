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

@enum GameState firstmove playing mined finished

mutable struct MineButton <: Gtk.GtkToggleButton
    handle::Ptr{Gtk.GObject}
    row
    column

    function MineButton(row, column)
        btn = GtkToggleButton()
        set_gtk_property!(btn, "width-request", 20)
        set_gtk_property!(btn, "height-request", 20)
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
        if tile.revealed
            if tile.mined
                set_gtk_property!(uitile, :label, "B")
            else
                set_gtk_property!(uitile, :label, tile.neighborcount)
            end
            set_gtk_property!(uitile, :active, true)
        elseif tile.flagged
            set_gtk_property!(uitile, :active, false)
            set_gtk_property!(uitile, :label, "F")
        else
            set_gtk_property!(uitile, :label, "")
        end
    end
end

function revealtiles!(array, tile)
    tile.revealed = true
    if tile.neighborcount == 0
        neighbors = filter(x -> !x.revealed,
                        getneighbors(array, tile.row, tile.column))
        for neighbor in neighbors
            revealtiles!(array, neighbor)
        end
    end
end

game = firstmove
win = GtkWindow("Don't Stand on Mines", 400, 200)
grid = GtkGrid()
push!(win, grid)
minefield = makeminefield(16, 30, 99)
maxrow, maxcolumn = size(minefield)
for i = 1:maxcolumn, j=1:maxrow
    b = MineButton(j, i)
    signal_connect(b, "button-release-event") do widget, event
        # on_button_clicked(widget, event)
        tile = minefield[widget.row, widget.column]
        # This should just change tile state
        if event.button == 1
            # left click
            # If revealed make sure still toggled
            if !tile.flagged
                if tile.mined
                    tile.revealed = true
                    game = mined
                    println("Tile mined.")
                    println(game)
                # Otherwise reveal self and set toggle
                else
                    revealtiles!(minefield, tile)
                    println("Newly revealed tile.")
                    # If self count = 0 reveal all unrevealed neighbors
                end
                set_gtk_property!(widget, :active, true)
            end
        elseif event.button == 3
            # right click
            # If revealed do nothing
            # If flagged unflag
            if !tile.revealed
                tile.flagged = !tile.flagged
            end
        elseif event.button == 2
            # Middle mouse is "2"
            # Maybe use for revealed square with correct total flags
        else
        end
        # Update the field
        updatefield!(minefield, grid)
    end
    setindex!(grid, b, i, j)
end

showall(win)
