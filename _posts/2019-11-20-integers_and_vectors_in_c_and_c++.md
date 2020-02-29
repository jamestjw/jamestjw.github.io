# Integers and Vectors in C/C++

Contents: 
1. TOC
{:toc}

## What's this all about?
{% include screenshot url="2019-11-20-integers_and_vectors_in_c_and_c++/binary.jpeg" %}

You might ask, why am I discussing this particular topic? Well recently, I have been following an online offering of Stanford's CS107 course which can be found <a href='https://see.stanford.edu/Course/CS107'>here</a>.
It discusses the implementation of lower level stuff within an operating system, such as how the data types we use in our daily life (e.g. integers, floats and strings) are actually laid out in memory. I especially love how we also
get to leverage our knowledge of the intricacies of such implementations to then implement even more commonly used data structures such as <b>Vectors</b> and <b>HashSets</b>.

## My plan for the day
{% include screenshot url="2019-11-20-integers_and_vectors_in_c_and_c++/coding.jpg" %}

To give you a taste of the fascinating stuff we learn in CS107, I will give you a quick introduction to a data type like <i>integer</i> is represented and laid out in memory. I will then talk about how we would implement a <i>Vector</i> in pure C that would allow us to store the integers that we will soon talk about.
This implementation of a Vector will leverage our knowledge of the would-be representation of integers in memory.

## Integers
I am going to make the assumption that you already know what an integer is, what I will then do is illustrate how might we represent something like this in memory. But first, I will first introduce the notion of bits and bytes. A bit can take either one of two values,
i.e. 0 or 1. In other words, we can use a bit to represent the absence/presence of something. Next, 8 bits make up a byte, naturally within a single byte we can imagine that all 8 bits are next to each other within memory.

{% include screenshot url="2019-11-20-integers_and_vectors_in_c_and_c++/binary2.png" %}

Here comes the interesting part, a typical integer is represented using 4 bytes, i.e. 32 bits. Using these 32 bits, we need to be able to represent every single possible integer that the client needs (we won't be able to, but for practical purposes we come close to being able to do so).
The above diagram doesn't illustrate the entirety of the 4 bytes I previously mentioned, it merely shows what 2 bytes (16 bits) would look like. Reading from right to left, each bit represents the absence or presence of that particular power of 2.
Hence, the integer represented in the diagram is 2<sup>0</sup> + 2<sup>2</sup> + 2<sup>5</sup> + 2<sup>6</sup> + 2<sup>7</sup> + 2<sup>11</sup> + 2<sup>15</sup> = 35045. Since there are 32 bits in 4 bytes, there are 2<sup>32</sup> = 4294967296 patterns that can possibly be represented. Which means that we can easily represent every single integer from 0 through 4294967295.
However, we would also be interested in representing negative numbers, we achieve this by using the most significant bit (the left most in the context of our diagram) to represent whether a number is positive or negative. Having sacrificed one bit to denote the sign of the number, what's left allows us to represent
numbers in the range of -2,147,483,648 to 2,147,483,647.

## Vector
Now that we have a rough idea of what an integer is like, let's consider writing a Vector class from scratch in the context of C. As a language, C allows the programmer to really get down and dirty to mess with dynamic memory
allocation, pointers and whatnot. This stuff may sound intimidating to the uninitiated, but this is the exactly the kind of stuff that we want to leverage to build this Vector class.

Dynamic memory allocation means that there are a couple of <b>responsibilities</b> that the programmer now needs to take care of:
* Asking for memory when necessary.
* Reallocating the given memory when more memory is requred.
* Free-ing the memory when it is no longer in use.

In order to store something, we need to allocate precisely the right amount of memory to store it, we are also responsible of keeping track of where it is and how much memory was allocated. But then again, we 
cannot only be responsible of creating something without eventually having to <b>dispose of it</b> when it is no longer needed, otherwise there would be an ever increasing amount of memory that is taken up unnecessarily!
With all that being said, you now have a very rough idea of the work that needs to be done. Now it's just a matter of actually doing it!

### Pointers
Before we get down and dirty with the implementation of a vector, I would need to do a brief introduction of the notion of 'pointers'. A pointer is basically a variable that points to the addresss of another variable. 

To briefly illustrate how a pointer works in C, suppose that I define the following <code>int *i = 7;</code>. Here the variable <code>i</code> itself is not an integer, instead <code>i</code> is a pointer to some place in memory that contains an integer with the value <code>7</code>. This means that if we follow up by doing something like <code>*i = 8;</code>, the value of <code>i</code> itself remains the same, however the integer that it points to will now have its value changed to <code>8</code>. The <code>*</code> notation is used to <b>dereference</b> a pointer. Dereferencing a pointer means the following, we follow the pointer to where it points to and we get access to the value located there. Perhaps now things are clearer, if <code>i</code> is a pointer to an integer, <code>*i</code> deferences the pointer and hence we get an integer.

{% include screenshot url="2019-11-20-integers_and_vectors_in_c_and_c++/pointer.png" %}

Pointers are ubiquitous in C programming, and it is so for a good reason. Pointers are just 4 byte figures, and they can be used to point to anything and everything. Suppose that there exists a huge data structure in your program, and you wish to pass it as a parameter to a particular function call, it would an incredible waste of space to pass in the entire data structure! You could alternatively set up your function in a way so that it accepts a pointer to the same data structure, this way the function will still be able to access the value of the said data structure by dereferencing the pointer.

### Vector Struct
{% include screenshot url="2019-11-20-integers_and_vectors_in_c_and_c++/struct.png" %}

In C, the closest thing to a class and object that we can get is a <i>struct</i>, we make do with what we can get. If you are familiar with the concept of a <i>class</i>, a struct is basically the same thing (well it compiles to nearly the same thing!) with minor differences.
In a class, the address/reference to the instance of the class is always passed to every method call. A struct also does not have the notion of public and private attributes and methods, everything is "public". In our case, our <code>vector</code> struct contains numerous attributes
and methods that will be instrumental to its operation during runtime.

We assume that <i>element size</i> stays constant throughout the use of a single vector, in other words we expect that any instance of a vector is only used to store
data of a particular type. Suppose that we intend to store integers within an instance of a vector, the <code>elemSize</code> would then be 4 because integers take up 4 bytes of memory.
<code>void *elems</code> is a pointer to a blob of memory that we shall use to the store the elements of the vector, this will be further elaborated on momentarily.
Here, we have the notion of a <i>logical length</i>, and an <i>allocated length</i>. The <code>logLength</code> is incredibly simple to understand, it is merely the number of elements within the vector.
The <code>allocLength</code> on the other hand refers to the number of elements that can potentially be stored in the amount of memory that has been allocated to the vector 
at any point in time. What really happens is that we will gradually <b>allocate more and more memory</b> to a vector instance as the number of elements it contains increases, 
this is relevant because we do not want to allocate a huge block of memory to a vector from the get-go. <code>increment</code> is incredible simple, as it simply denotes how much will we 
expand our vector by when necessary, for the sake of simplicity we shall assume that the vector has its size increased by the same amount every time. <code>freeFn</code> might seem like an odd one, but what it really does is store a function that knows how to dispose of elements within the vector. If this is confusing, consider this, as mentioned before dynamic memory allocation brings with it the need
to free up memory once we are done. Built-in data types like integers and floats will automatically be freed as they fall out of scope. However, suppose that the elements in the vector are themselves dynamically allocated, which means that 
we are actually responsible of disposing of them when we are done. The <code>freeFn</code> is a function that knows how to correctly free each element within the vector.

### Constructor

{% include screenshot url="2019-11-20-integers_and_vectors_in_c_and_c++/constructor.png" %}

If you are familiar with <b>object-oriented programming</b>(OOP), you might be familiar with the concept of a constructor. A constructor is a method called upon initialisation of class, and it is responsible for getting things all set up in anticipation of the client's usage of the said class.
However, like I mentioned before, C does not support OOP (remember that we are using a struct). Hence, this 'constructor' that we are defining is merely something that would mimic what a real constructor would do.

Note that the first parameter <code>vector *v</code> is actually a pointer to an instance of a vector, remember how I said that methods in OOP typically will have references to an instance of the class? The next parameter <code>int elemSize</code> refers to the number of bytes that each element would take up within this vector, remember that each instance of the <i>vector</i> that we are implementing should only hold elements of one particular type only. This will probably be one of the most used attributes of our vector implementation. As mentioned before, the <code>VectorFreeFunction freeFn</code> is a function that the client will need to provide, and it is responsible of disposing of the elements within our vector (whenever necessary). <code>int initialAllocation</code> is something important too, remember that we will be dynamically allocating memory to store the client's elements? Therefore, we need to know just how much memory should we allocate initially.

Moving on to the actual implementation of the function, we do a couple of things that are very intuitive, and also a few things that might be new to someone who has never worked with C before. We first make sure that <code>elemSize</code> is greater than zero for obvious reasons. We also allow <code>initialAllocation</code> to be 0, and the client can opt to pass in such a value, after which we shall set it to a default value of 10.

### -> notation
For those who are strangers to the <code>-></code> notation, I shall provide a brief introduction. Suppose that the variable on the left side of the arrow is a pointer, <code>pointer -> attribute</code> basically follows the pointer to where it points to and accesses the attribute on the right of the arrow. In other words, <code>v -> elemSize = elemSize</code> basically follows the pointer to where the vector instance really resides in memory and accesses the <code>elemSize</code> variable, and finally sets it to the value of <code>elemSize</code> (which is a parameter of this function).

Here's our strategy for implementing our vector, we are going to initialise it so that it has enough memory to store <code>allocLength</code> (allocated length) number of elements. At the start, although it can hold <code>allocLength</code> number of elements, it really has a <code>logLength</code> (logical length) of 0. And we do exactly that, the vector has the attributes <code>allocLength</code> and <code>logLength</code> initialised in that exact manner.

### malloc
<code>malloc</code> is a function that is core to C programming, and it is something that is built-in within the language. It takes precisely one parameter, i.e. how many bytes of memory should it allocate on your behalf.  <code>malloc</code> will go to the heap and find a block of memory that fits your requirements, it will then reserve it for your use and return a pointer to the said block.

We know that we want our vector to have an initial capacity of <code>allocLength</code>, to make it happen we call malloc and tell it we need a blob of memory that is <code>elemSize * v -> allocLength</code> wide. Note how we <b>don't </b>directly do <code>malloc(v -> allocLength)</code> as we need to take into account the size of each element! Remember that malloc returns a pointer to the allocated block of memory, we then assign it to <code>v -> elems</code>. However, there is a chance that malloc fails to get you the space that you need (perhaps you are out of memory?), hence we need to check if it returned us a NULL pointer.

Lastly, we also assign a <code>freeFn</code> to each vector, which I will briefly explain next.

## VectorFreeFunction

{% include screenshot url="2019-11-20-integers_and_vectors_in_c_and_c++/freeFn.png" %}

The above is the prototype of the <code>VectorFreeFunction</code>. You might say that this contains nothing, but that's just it, only the client knows how each element in the vector should be cleared up. The client will be responsible of writing a function that disposes of the elements whenever it is required, otherwise the client will be expected to pass in a NULL pointer.

## Length

{% include screenshot url="2019-11-20-integers_and_vectors_in_c_and_c++/length.png" %}

What this function does is pretty self explanatory. But then again, you might ask, if the implementation of the function is so simple, why do we even bother defining it? This is because we do not want the client to be directly interacting with <code>v -> logLength</code>, this is consistent with the <b>Encapsulation</b> aspect of OOP. Although there is no notion of hidden variables, we still try our best to make the usage of our vector implementation as clean as possible.

## Realloc

{% include screenshot url="2019-11-20-integers_and_vectors_in_c_and_c++/realloc.png" %}

Before moving on to the rest of the implementation, we first need to get this out of the way. Suppose that we wish to add a new element to our vector, but unfortunately we find that it has reached its maximum capacity, i.e. <code>v -> logLength == v -> allocLength</code>. Sticking to the strategy that we defined earlier, we seek to increase its allocated length by a fixed amount that was decided in the initialisation of the vector. Hence, we increase the <code>allocLength</code> by that amount. Next, we need to actually handle the increase of the allocated size.


<code>realloc</code> is the good friend of <code>malloc</code>. Given that we have a pointer to a block of memory that allocated by <code>malloc</code>, <code>realloc</code> is capable of extending our current block of memory to have a bigger capacity, or finding us a new block of memory that is bigger, and then returning a pointer to it. <code>realloc</code> takes 2 parameters, the first is a pointer that <code>malloc</code> once returned, the second is the size of which <code>realloc</code> should expand the block of memory to. Suppose that you pass <code>realloc</code> a size that is smaller than the space the block of memory is currently occupying, most implementations of <code>realloc</code> simply just do not do anything, i.e. we do not need to reallocate the memory to make it smaller.

## Append

{% include screenshot url="2019-11-20-integers_and_vectors_in_c_and_c++/append.png" %}

Appending to a list is something we do quite often, to pull off this function, the client is required to pass in a pointer to the element that needs to be appended to the list. But before we do any appending, we first check if a reallocation is necessary. If the coast is clear, we then call <code>memcpy</code>.

### memcpy
<code>memcpy</code> takes 3 parameters, the first parameter is a pointer to the destination of which the copying of bytes should occur. The second parameter is the pointer to the base address of the bit pattern that we wish to copy to the destination. The third parameter is simply how many bytes that needs to be copied. In a nutshell, <code>memcpy</code> copies an arbitrary amount of bytes from the base address of the source pointer to the destination.

And if you think about this, this makes perfect sense. We copy the bit pattern of the element that the client provides to the end of the array by leveraging <code>memcpy</code>, and that's it! Also, we musn't forget to increase the <code>logLength</code> of the vector.

## Insert
{% include screenshot url="2019-11-20-integers_and_vectors_in_c_and_c++/insert.png" %}

Insert is basically a more powerful version of append, because the client gets to choose where does he want the element to be inserted at. It takes one more parameter than <code>VectorAppend</code>, i.e. the position in which the element should be inserted at. We do the necessary check that the <code>position</code>> to add the new element in is actually a valid position in the vector. As before, we also check if a reallocation is necessary. To make things easier, if the client decides to add an element at the end of the vector, we should just call <code>VectorAppend</code> which basically does exactly that. But otherwise, we are in for a little bit more work.

### memmove
<code>memmove</code> is the more sophisticated cousin of <code>memcpy</code>. This is because <code>memcpy</code> has the requirement that the source and destination bit patterns do not overlap with one another. <code>memmove</code> on the other hand, checks for such an overlap and does the necessary adjustments to pull off what <code>memcpy</code> does.

Back to the insert operation, suppose that the client wants to insert an element in the middle of the vector, we would need to then push all the other elements to the right to make space for this new element. And that is precisely what the first call to <code>memmove</code> does, recall that the function prototypes of <code>memmove</code> and <code>memcpy</code>  are the same, i.e. they take the same parameters. Also note that if we are copying elements such that they all move one 'unit' to the right, there is a chance that the source and destination bit patterns will be on overlapping blocks of memory.
The subsequent call to <code>memcpy</code> does the same thing as the one in <code>VectorAppend</code> did. Notice that since we know for a fact that no overlap in bit pattern can possibly occur here, we opt to use <code>memcpy</code> instead of <code>memmove</code>. Since <code>memmove</code> checks for overlaps, unnecessarily doing so makes the implementation slower and we should avoid it whenever possible.

## Accessing the Nth Element
{% include screenshot url="2019-11-20-integers_and_vectors_in_c_and_c++/nth.png" %}
Given that we have the means of populating our vector, we now need a way to access the nth element of the vector, alternatively this is also called indexing into the vector. The responsibility of this function is simple, given an integer which is less than the logical length of a vector, the function will then return a pointer to the element in that particular position of the vector.

The implementation of the function itself is pretty simple, we just need to return a pointer that is <code>position</code> number of elements worth of bytes away from the base address of the elements.

## Delete
{% include screenshot url="2019-11-20-integers_and_vectors_in_c_and_c++/delete.png" %}
Now that we are capable of adding things to the vector and indexing into it, we also need to know how we can remove things from it. The function requires the client to tell it which element to remove. First things first, function first checks if a <code>freeFn</code> was defined, if it is defined, it would mean that the elements require additional treatment to be disposed of. Remember the rule of thumb I mentioned earlier, if memory was dynamically allocated using <code>malloc</code>, it would then need to be <code>free</code>-ed, the <code>freeFn</code> is responsible of making sure that this all happens correctly. We leverage <code>VectorNth</code> to get a pointer to the element to be free-ed, and we let the <code>freeFn</code> do its job.

Suppose that the element the client wants to remove is the last element in the vector, then all we have to do is ignore the last element in the array and decrement the logical length (remember that if the element requires disposing of, the <code>freeFn</code> has already taken care of it). However, suppose that the element that the client wishes to remove is in anywhere but the last <code>position</code> of the vector, it would mean that we would need to shift every element to the right of that <code>position</code> <b>one unit to the left</b>. Therefore, we need to copy bit patterns in order to shift things to the left, it is probably not too difficult to figure out that source and destination bytes would definitely be overlapping, hence we make use of <code>memmove</code> instead of <code>memcpy</code>.

## Sort
### VectorCompareFn
{% include screenshot url="2019-11-20-integers_and_vectors_in_c_and_c++/compareFn.png" %}
The <code>VectorCompareFn</code> has two parameters, each of them is a pointer to 2 elements that we wish to compare. If the first element is 'greater' than the second element, the function is expected to return a <b>positive</b> integer, if the first element is 'lesser' than the second element, the function is then expected to return a <b>negative</b> integer. If they are both equal, the function is expected to return a <b>zero</b>. The sorting algorithm will then sort the elements of our vector based on the behaviour of this comparison function. The client will be responsible of providing our vector implementation with this function, since no one but the client is really aware of what elements will be placed inside a vector.

### Implementation
{% include screenshot url="2019-11-20-integers_and_vectors_in_c_and_c++/sort.png" %}

When you have a list of items, it is a natural that you would want to sort it. We make use of a C library function <code>qsort</code> to help us with the sorting. It takes a couple of parameters, the first element is <code>void *base</code>, which is a pointer to the base address of the block of memory that we use to store our elements. The second parameter <code>size_t nitems</code> is the number of elements contained in our vector. The third parameter <code>size_t size</code> refers to the size in bytes of each element in our vector. The last parameter is a pointer to a function that can be used to compare two elements that can possibly be found in an instance of our vector, and this plays a part in sorting the elements.

So here's what we pass into <code>qsort</code>, <code>v -> elems</code> as the base address of our element array, <code>v -> logLength</code> as the logical length of our vector, <code>v -> elemSize</code> as the size of each element in the vector, and finally the <code>VectorCompareFn</code> function that we just spoke of. The <code>qsort</code> function will use the information we gave it to sort the elements in place.

## Map
### VectorMapFunction
{% include screenshot url="2019-11-20-integers_and_vectors_in_c_and_c++/mapFn.png" %}

A <code>VectorMapFunction</code> is pointer to a client defined function. Given a pointer to a particular element stored in an instance of a vector, this function is responsible of applying some sort of operation on it. To fulfill its responsibility, it can optionally employ the use of the optional <code>auxData</code> parameter. This can also serve to make the implementation of a <code>VectorMapFunction</code> more dynamic.

### Implementation
{% include screenshot url="2019-11-20-integers_and_vectors_in_c_and_c++/map.png" %}

 A map function is something that is extremely useful when we have a collection of elements within a vector as it allows us to do some operation to all of the elements at the same time. It takes two parameters, the first is a <code>VectorMapFunction</code> which is basically a function that will be applied on each element within the vector. <code>auxData</code> is a parameter that exists for the sake of convenience, suppose that the <code>VectorMapFunction</code> requires an extra piece of information in order to carry out its job, then this is how we can pass it in. All that is left is just to loop over each element within our vector and called the <code>VectorMapFunction</code> on it.

## Search
{% include screenshot url="2019-11-20-integers_and_vectors_in_c_and_c++/search.png" %}

If the client had a huge collection of elements in a vector and wishes to search for a particular one, this search function becomes useful. Given a pointer to a search <code>key</code> as the first parameter, a <code>VectorCompareFn</code> as the second parameter, a <code>startIndex</code> which tells the vector from which element to begin search for the target key as the third element, and a boolean <code>isSorted</code> to tell the search implementation whether or not the elements are already sorted as a final parameter, the search function will return the <b>index</b> at which the search key can be found. If the key does not exist in the vector, a <b>-1</b> will be returned.

Suppose that the elements are already sorted, we can leverage the built-in <code>bsearch</code> function that will be able to quickly complete the task. <code>bsearch</code> takes a few parameters, the first of which is a pointer to the search key. Next, it takes the base address of the array that is to be searched. The third parameter contains the number of elements that are within the array to be searched. The fourth parameter is the size of each element  within the array, and the last is a comparison function (similar to the one that was discussed in the sort function). If <code>bsearch</code> is successful in finding the element, it returns a pointer to the resulting element, otherwise it returns a null pointer.

If the elements are not sorted however, we will then have to rely on another built-in C function <code>lfind</code>. It takes the exact same parameters as <code>bsearch</code>, save for a minor difference, i.e. instead of directly taking in the number of elements that are within the array to be searched, it requires a pointer to that number. Its return behaviour is also similar to that of <code>bsearch</code>.

If the search functions return a non NULL pointer, implying that the search was successful, we will then need to calculate the offset of the pointer to the found element from the base address of the array and divide the result by the size of each element. If the above works out we will be left with the index at which the client is able to find the desired element.

## That's all it takes!
The above is all we really need to have minimally viable implementation of a vector in C! Vector-like data structures are things that we use on a daily basis, however we tend to take it granted by virtue of how 'primitive' and 'common' it appears to us. Most programming languages will come with its own version of a <code>vector</code>, and they will be most certainly be built on top of the concepts we just discussed. The next time you use a vector, perhaps you will be reminded of the conveniences that the built-in vector implementation brings to the table!