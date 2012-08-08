x = Foo[*
  y do
    z
  end
]

x = Foo[* # with a comment
  y do
    z
  end
]

x = *
  array.map do
  3
end

x = Foo[*
  y {
    z
  }
]

x = Foo(*y do
  z
end)

foo(1,
    2,
    *)
