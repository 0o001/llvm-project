// Clear and create directories
// RUN: rm -rf %t
// RUN: mkdir %t
// RUN: mkdir %t/cache
// RUN: mkdir %t/Inputs

// Build first header file
// RUN: echo "#define FIRST" >> %t/Inputs/first.h
// RUN: cat %s               >> %t/Inputs/first.h

// Build second header file
// RUN: echo "#define SECOND" >> %t/Inputs/second.h
// RUN: cat %s                >> %t/Inputs/second.h

// Test that each header can compile
// RUN: %clang_cc1 -fsyntax-only -x objective-c %t/Inputs/first.h -fblocks -fobjc-arc
// RUN: %clang_cc1 -fsyntax-only -x objective-c %t/Inputs/second.h -fblocks -fobjc-arc

// Build module map file
// RUN: echo "module FirstModule {"     >> %t/Inputs/module.map
// RUN: echo "    header \"first.h\""   >> %t/Inputs/module.map
// RUN: echo "}"                        >> %t/Inputs/module.map
// RUN: echo "module SecondModule {"    >> %t/Inputs/module.map
// RUN: echo "    header \"second.h\""  >> %t/Inputs/module.map
// RUN: echo "}"                        >> %t/Inputs/module.map

// Run test
// RUN: %clang_cc1 -fmodules -fimplicit-module-maps -fmodules-cache-path=%t/cache -x objective-c -I%t/Inputs -verify %s -fblocks -fobjc-arc

#if !defined(FIRST) && !defined(SECOND)
#include "first.h"
#include "second.h"
#endif

#if defined(FIRST) || defined(SECOND)
@protocol NSObject
@end

__attribute__((objc_root_class))
@interface NSObject
@end

@protocol P1
@end

@protocol P2
@end

@interface I1
@end

@interface I2 : I1
@end

@interface Interface1 <T : I1 *> {
@public
  T x;
}
@end

@interface Interface2 <T : I1 *>
@end

@interface Interface3 <T : I1 *>
@end

@interface EmptySelectorSlot
- (void)method:(int)arg;
- (void)method:(int)arg :(int)empty;

- (void)multiple:(int)arg1 args:(int)arg2
                :(int)arg3;
- (void)multiple:(int)arg1 :(int)arg2 args:(int)arg3;
@end

#endif

#if defined(FIRST)
struct S1 {
  Interface1 *I;
  int y;
};
#elif defined(SECOND)
struct S1 {
  Interface1 *I;
  float y;
};
#else
struct S1 s;
// expected-error@second.h:* {{'S1::y' from module 'SecondModule' is not present in definition of 'struct S1' in module 'FirstModule'}}
// expected-note@first.h:* {{declaration of 'y' does not match}}
#endif

#if defined(FIRST)
@interface Interface4 <T : I1 *> {
@public
  T x;
}
@end
@interface Interface5 <T : I1 *> {
@public
  T x;
}
@end
@interface Interface6 <T1 : I1 *, T2 : I2 *> {
@public
  T1 x;
}
@end
#elif defined(SECOND)
@interface Interface4 <T : I1 *> {
@public
  T x;
}
@end
@interface Interface5 <T : I1 *> {
@public
  T x;
}
@end
@interface Interface6 <T1 : I1 *, T2 : I2 *> {
@public
  T2 x;
}
@end
#endif

// Test super class mismatches
#if defined(FIRST)
@interface A1 : I1
@end
#elif defined(SECOND)
@interface A1 : I2
@end
#else
A1 *a1;
// expected-error@first.h:* {{'A1' has different definitions in different modules; first difference is definition in module 'FirstModule' found super class with type 'I1'}}
// expected-note@second.h:* {{but in 'SecondModule' found super class with type 'I2'}}
#endif

#if defined(FIRST)
@interface A2
@end
#elif defined(SECOND)
@interface A2 : I1
@end
#else
// expected-error@first.h:* {{'A2' has different definitions in different modules; first difference is definition in module 'FirstModule' found no super class}}
// expected-note@second.h:* {{but in 'SecondModule' found super class with type 'I1'}}
A2 *a2;
#endif

#if defined(FIRST)
@interface A3 : I1
@end
#elif defined(SECOND)
@interface A3 : I1
@end
#else
A3 *a3;
#endif

#if defined(FIRST)
@interface A4 : I1
@end
#elif defined(SECOND)
@interface A4
@end
#else
A4 *a4;
// expected-error@first.h:* {{'A4' has different definitions in different modules; first difference is definition in module 'FirstModule' found super class with type 'I1'}}
// expected-note@second.h:* {{but in 'SecondModule' found no super class}}
#endif

// Test number of protocols mismatches
#if defined(FIRST)
@interface B1 : NSObject <P1>
@end
#elif defined(SECOND)
@interface B1 : NSObject <P1>
@end
#else
B1 *b1;
#endif

#if defined(FIRST)
@interface B2 : NSObject <P1>
@end
#elif defined(SECOND)
@interface B2 : NSObject
@end
#else
B2 *b2;
// expected-error@first.h:* {{'B2' has different definitions in different modules; first difference is definition in module 'FirstModule' found 1 referenced protocol}}
// expected-note@second.h:* {{but in 'SecondModule' found 0 referenced protocols}}
#endif

#if defined(FIRST)
@interface B3 : NSObject
@end
#elif defined(SECOND)
@interface B3 : NSObject <P1>
@end
#else
B3 *b3;
// expected-error@first.h:* {{'B3' has different definitions in different modules; first difference is definition in module 'FirstModule' found 0 referenced protocols}}
// expected-note@second.h:* {{but in 'SecondModule' found 1 referenced protocol}}
#endif

#if defined(FIRST)
@interface B4 : NSObject <P1>
@end
#elif defined(SECOND)
@interface B4 : NSObject <P2>
@end
#else
// FIXME: Silently accept this for now. Clang should emit an error when
// ODR hash for protocols is implemented.
B4 *b4;
#endif

// Keep macros contained to one file.
#ifdef FIRST
#undef FIRST
#endif

#ifdef SECOND
#undef SECOND
#endif
