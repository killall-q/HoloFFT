# HoloFFT
###### for [Rainmeter](https://www.rainmeter.net/)
Displays audio FFT as 3D point cloud visualizations.

## Features

* Scale, rotate, and apply perspective to visualizations
* Choose from 23 presets or create your own
* Fade, gradient, and spectrum coloring

For an explanation of the 3D rendering algorithm, see [Hologram](https://github.com/killall-q/Hologram).

###### [Full description and download](http://killall-q.deviantart.com/art/HoloFFT-600443429)

---

## Creating Your Own Visualizations

#### Overview

Custom visualizations can be made for HoloFFT by writing Lua code, which HoloFFT will convert into a function. This function calculates the _x_, _y_, and _z_ coordinates of a set of points, one point at a time, 40 times a second.

This is how many points you have to work with:

> bands × rows = number of points

Each row holds one frame of FFT data history. Each point represents an FFT value, ranging from 0 to 1. The function should work for any quantity of bands and rows, which is determined by the user. Points can neither be created or destroyed on the fly.

Each update, live FFT data is fed into the last row, and previous FFT data is pushed towards the first row.

If a visualization you make is interesting and unique enough, I'll include it as a default preset in HoloFFT!

If you have an idea for a visualization but math is not your forte, post a comment in one of the places I've advertised HoloFFT and I'll see what I can do.

#### Getting Started

Go to this directory:

    Documents\Rainmeter\Skins\HoloFFT\@Resources\Presets\

Duplicate the file of an existing preset, and open it in your favorite text editor.

#### Function Outline

A basic visualization function (Plane.lua is shown) looks like this:
```lua
local bands, b, rows, r, v = ...

-- YOUR CODE HERE
local x = b / bands * 2 - 1
local y = 1 - r / rows * 2
local z = v - 0.5
-- YOUR CODE HERE

return x, y, z
```
HoloFFT will convert the above into this function:
```lua
function Preset(bands, b, rows, r, v)
    local x = b / bands * 2 - 1
    local y = 1 - r / rows * 2
    local z = v - 0.5
    return x, y, z
end
```
Which will then be used like so:
```lua
local x, y, z = Preset(bands, b, rows, r, FFT[b][r])
```
Therefore, it is imperative that you __do not modify the code outside of the "YOUR CODE HERE" comments.__

Functions are restricted to the use of these input variables:

* __bands__  
total number of bands
* __b__  
number of current band, ranging from 0 to (bands - 1)
* __rows__  
total number of rows
* __r__  
number of current row, ranging from 1 to rows
* __v__  
value of FFT at current band and row, ranging from 0 to 1

Additionally, you can use any built-in [Lua 5.1 functions](http://www.lua.org/manual/5.1/#index). Global variables and external Lua libraries cannot be used. Rainmeter [variables](https://docs.rainmeter.net/manual/lua-scripting/#GetVariable) and measure values are allowed, but I have not tested to see if they pose a performance penalty.

Functions must return ___x___, ___y___, and ___z___ coordinates, in that order.

These are the recommended coordinate ranges for visualizations to fill the render space, for the following volume domains:

* Domain: Cube  
_x_: [-1, 1]  
_y_: [-1, 1]  
_z_: [-1, 1]
* Domain: Cylinder  
_x_: [-√2, √2]  
_y_: [-√2, √2]  
_z_: [-1, 1]
* Domain: Sphere  
_x_: [-√3, √3]  
_y_: [-√3, √3]  
_z_: [-√3, √3]

If that bit made your eyes glaze over, just assume that no computed coordinate should go beyond ±1. The reason for these peculiar restrictions is so that visualizations can be arbitrarily rotated without going outside of the square render space. Points outside of the domain might not be rendered.

#### Basic Formula Components

No matter how complex a visualization looks, most visualizations are just creative combinations of a few basic components. Listed here are only a few of the infinite possibilities.

[Desmos](https://www.desmos.com/calculator), a free online graphing calculator, may be useful.

###### Progress along bands
Fractional progress along the range of bands, ranging from 0 to 1.
```lua
b / bands
```

###### Progress along rows
Multiply these formulas by `v` to achieve the illusion of smooth motion of a "particle":

Constant velocity
```lua
r / rows
```
Smooth velocity curve from zero to positive (constant positive acceleration)
```lua
math.sin(r / rows * 1.57)
```
Smooth velocity curve from positive to zero (constant negative acceleration)
```lua
1 - math.cos(r / rows * 1.57)
```
Smooth velocity curve from zero to positive to zero (constant positive, then constant negative acceleration)
```lua
(1 - math.cos(r / rows * 3.14)) * 0.5
```
![velocity along rows](http://i.imgur.com/FvpBJCp.gif)

###### Cylinder conversion
The foundation of any cylindrical visualization, tack on various multiplicands to create variations on a basic cylinder. After that, you can calculate the _z_ variable however you wish.
```lua
local theta = b / bands * 6.28
local x = math.cos(theta)
local y = math.sin(theta)
```

###### Cylinder conversion with half-circle twist
All default cylindrical and spherical presets incorporate the same twist that creates a visually appealing effect when the visualization is automatically counter-rotated. They would be quite boring otherwise.
```lua
local theta = b / bands * 6.28 + r * 0.02454
```
`r * π / 128 = r * 0.02454`

###### Value scaling
`v`, the FFT value, is what makes your visualization react to audio. Use it as a coefficient for other components.

Linear — uniform scaling
```
v
```
Square — lower values of `v` have a lesser effect
```lua
v^2
```
Root — lower values of `v` have a greater effect
```lua
v^0.5
```
Inverse Square — higher values of `v` have a lesser effect
```lua
1 - (v - 1)^2
```
Inverse Root — higher values of `v` have a greater effect
```lua
1 - (1 - v)^0.5
```
![value scaling](http://i.imgur.com/jONYq0r.gif)

#### Advanced Formula Components

###### Pseudorandom number generator
While `math.random()` can be used to generate random numbers, you may wish for the random number to persist to the next row in the next frame. For that, we derive our "random" number from `v`, because `v` is the only persistent input variable that carries from row to row, frame to frame.
```lua
v % 0.1
```
_Used in:_ Grid, Spray

###### Value-scaled sine wave
A sine wave with frequency and amplitude uniformly scaled by `v`. One of many ways to induce sinusoidal motion in the FFT "particle".
```lua
math.sin((1 - r / rows) * 6.28 / v) * v
```
_Used in:_ Sine

###### Separation of bands into square 2D grid
Always produces a square grid even if the number of bands is not a perfect square, for unknown reasons.
```lua
local br = bands^0.5 -- square root of bands
local x = math.floor(b / bands * br) / br * 2 - 1
local y = (b % br) / br * 2 - 1
```
_Used in:_ Grid

###### Basic sphere
Produces a sphere with FFT data perturbing radially from the origin.
```lua
local theta = b / bands * 6.28
local v = 0.2 + v * 0.8 -- minimum radius of 0.2
local x = math.cos(theta) * math.sin(r / rows) * v
local y = math.sin(theta) * math.sin(r / rows) * v
local z = -math.cos(r / rows) * v
```
_Used in:_ Sphere

###### Point hiding
Division by zero causes the value of a variable to be `NaN`, which prevents the point from being rendered without causing any errors, for unknown reasons. Lua does not allow a variable to be directly assigned a value of `NaN`.

You can incorporate this error into your equations or use a conditional with ternary. Only one of the return variables needs to be `NaN`.
```lua
0 / 0
```
_Used in:_ Sine

###### Control structures
You can use Lua if..else statements, [ternary](http://lua-users.org/wiki/TernaryOperator), and other control structures. See the [Lua 5.1 manual](http://www.lua.org/manual/5.1/manual.html#2.4.4) for details.
