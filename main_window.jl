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

function setneighborcount!(array, square::Minesquare)
    square.neighborcount = 0
    neighbors = getneighbors(array, square.row, square.column)
    for neighbor in neighbors
        if neighbor.mined
            square.neighborcount += 1
        end
    end
end

function makeminefield(numrows, numcolumns, nummines)
    mine_field  = [Minesquare(i, j) for i=1:numrows, j=1:numcolumns]
    seedfield!(mine_field, nummines)
    for tile in mine_field
        setneighborcount!(mine_field, tile)
    end
    return mine_field
end

function on_button_clicked(w)
  println("Button $(w.row), $(w.column) has been clicked")
end

function updatefield!(array, grid)
    maxrow, maxcolumn = size(array)
    for i=1:maxrow, j=1:maxcolumn
        tile = array[i, j]
        if tile.mined
            set_gtk_property!(getindex(grid, j, i), :label, "B")
        else
            set_gtk_property!(getindex(grid, j, i), :label, tile.neighborcount)
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
    signal_connect(on_button_clicked, b, "clicked")
    setindex!(grid, b, i, j)
end

updatefield!(minefield, grid)
showall(win)
