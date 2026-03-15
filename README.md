<p align="center">
  <h1 align="center"><i><ins>Aery</ins></i></h1>
</p>

<p align="center">
  <b><i>More than a garbage collector for Luau and the Allure Ecosystem.</i></b>
</p>

## 📦 Installation
Install via wally:
```
Aery = "r-iva9/aery@1.0.0"
```

## 🍀 Why not Maid?

### *1. Dependencies, as I call them*

Create an Aery with some dependencies:
```luau
local myAery = Aery:Aery(
  {foo = 10},
  {bar = 20}
)
```
The Aery itself is empty, and will still be empty if you clean it, but I can already reference `foo` and `bar`.
```luau
myAery:Insert(function()
  print(myAery.foo + myAery.bar)
end)

myAery:Clean() --30
```
### 2. Referencing the parent

Create an Aery inside of an Aery:
```luau
local myAery = Aery:Aery(
  {foo = 10},
  {bar = 20}
)

local secondAery = myAery:Aery(
  {baz = 30}
)
```
The `secondAery` can reference `foo` and `bar` too, and also `baz`!
```luau
print(secondAery.foo) --10
```
The same works with contents:
```luau
myAery.garbage = "litter"

print(secondAery.garbage) --litter
```
Cleaning the parent Aery cleans the child Aery:
```luau
myAery.test = function()
  print("myAery cleaned!")
end
secondAery.test = function()
  print("secondAery cleaned!")
end

myAery:Clean()
-- myAery cleaned!
-- secondAery cleaned!
```

### 3. Custom cleaning wrappers

You can pass a table with custom cleanup functions for value types.

For example, let's ***not clean*** number values and instead increment them by 20:
```luau
local myAery = Aery:Aery()

myAery.value = 10
myAery.garbage = "text"

myAery:Clean {
  number = function(key, value, future)
    future[key] = value + 20
  end
}
```
This will clean everything, except for `value`, because it's a `number`. It will change it's value to `30`.

You can save the wrapper, not to pass it each time you clean the Aery:

```luau
local myAery = Aery:Aery()

myAery:Wrapper {
  number = function(key, value, future)
    future[key] = value + 20
  end
}

myAery.value = 10
myAery.garbage = "text"

myAery:Clean()
myAery:Clean()
```
Can you guess what happened to `value = 10`? Correct: it turned to `50`.

You can clean Aeries via 3 methods:
```luau
Aery:Clean(myAery)
myAery:Clean()
myAery()
```

## License

Aery is shared freely with the MIT license, it's a part of the Allure Ecosystem, which is entirely licensed under MIT.
<br>*For more information refer to https://github.com/r-iva9/Allure*
<br>Give me a shoutout if you want!
