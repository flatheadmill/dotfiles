Interrupt

 * Don't use your exception to pass state to the catch block. The catch block
 should have all the state it needs to resolve the error in its stack frame. If
 not, then it shouldn't be trying to do anything.
