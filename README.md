<p align="center">
  <h1 align="center"><i><ins>Aery</ins></i></h1>
</p>

<p align="center">
  <b><i>More than a maid-like garbage collector<br>for Luau and the <a href=https://github.com/r-iva9/Allure>Allure Ecosystem</a></i></b>
</p>

## 📦 Installation
Install via wally:
```
Aery = "r-iva9/aery@1.0.1"
```

## ⚒️ Basic usage

Create a new Aery:
```luau
local myAery = Aery:Aery()
```
Insert tasks into your Aery, like functions or values:
```luau
myAery.value = 10
myAery.play = function() end

myAery:Insert(function()
  print("Something happened!")
end)
myAery:GiveTask(function() end)
```
Cleanup your Aery via any of the three:
```luau
myAery()
myAery:Clean()
Aery:Clean(myAery)
```
During cleanup functions are called, signals are disconnected, threads are closed, the table itself is cleaned and more.

Those were the basics! For the cool stuff look below.

## 🍀 Why not Maid?

### *1. Components*

Create an Aery with some components:
```luau
local myComponents = {
  foo = function()
    print("foo")
  end
}

local myAery = Aery:Aery(
  myComponents,
  {bar = 20}
)
```
You can list as many components as you want inside of `Aery()`.
<br>The point is, you will be able to reference them through the created Aery:
```luau
myAery.foo() --foo
print(myAery.bar) --20
```
Components don't conflict with the contents inside of Aery, it's empty.

### *2. Referencing the parent Aery*

Create an Aery inside of an Aery:
```luau
local myAery = Aery:Aery()
local smallAery = myAery:Aery()

myAery.garbage = function() end
```

The thing is, I can reference `garbage` from `myAery` via `smallAery`:
```luau
print(smallAery.garbage) --function
```
The same works with components:
```luau
local myAery = Aery:Aery(
  {Component = function() end}
)
local smallAery = myAery:Aery()

smallAery:Component()
```

We're referencing the parent Aery and what it's components via the child Aery.

### *3. Aeries as components*

We're not actually making a child Aery, we're just making a new Aery with the "parent" Aery as a ***component***.
<br>We can always add more components, more Aeries.

```luau
local Aery1 = Aery:Aery()
local Aery2 = Aery:Aery()

local smallAery = Aery:Aery(Aery1, Aery2)
```

I can reference both all components from `Aery1` and `Aery2` and contents from both, via `smallAery`.

> [!NOTE]
> When we did `myAery:Aery()`, we didn't just use `myAery` as a component - the new small aery is also ***inserted*** into `myAery`, thus cleaning `myAery` will clean the child `smallAery`.

> [!NOTE]
> Because of this, cleaning `Aery1` or `Aery2` will not clean `smallAery`.
> <br>Just insert the `smallAery` into wherever you need it to be:
> ```luau
> Aery1:Insert(smallAery)
> ```
> Now cleaning `Aery1` will also clean `smallAery`

### *4. Custom cleaning wrappers*

You can pass a table with custom cleanup functions for value types.

```luau
local myAery = Aery:Aery()

myAery.garbage = function()
  print("It's cleaned!")
end
myAery.litter = "text"

myAery:Clean {
  string = function(key, value, future)
    print("I've cleaned the string", value, "assiged to key", key)
  end
}
```
```luau
-- Output
It's cleaned!
I've cleaned the string text assigned to key litter
```

I've listed a wrapper that will be called for each `string`, cleaned in `myAery`.
<br>The `future` argument is the table for future values, after cleanup. You can use this to avoid cleanup:
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
This will clean everything, except for `value`, because it's a `number`. It will change it's value to `10 + 20 = 30`.

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

### 5. Made for people

You literally can avoid using Aeries:
```luau
local garbage = {
  litter = function()
    print("litter is cleaned")
  end,
  theresMore = 10
}

Aery:Clean(garbage) --litter is cleaned
```

For cleanup you can use any of the three:
```luau
Aery:Clean(myAery)
myAery:Clean()
myAery()
```
And pass the custom cleanup wrapper in any of the three, including the example above, too.

## License

Aery is shared freely with the MIT license, it's a part of the Allure Ecosystem.
<br>*For more information refer to https://github.com/r-iva9/Allure*
<br>Give me a shoutout if you want!
