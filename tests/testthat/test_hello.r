context( "Testing functions in file hello.R" )

describe( "hello()", {
   describe( "Smoke Tests", {
      it( "Runs without error for simplest inputs and defaults.", {
         # expect_silent( hello() )
         expect_output( hello(), "Hello, world!" )
      })
   })
})
