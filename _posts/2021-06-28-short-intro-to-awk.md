---
tags: awk soen data_processing tutorial
---

# Short Intro to awk for Quick and Dirty Data Processing

## What got me into awk?

A few days ago I watched this [fantastic interview](https://youtu.be/O9upVbGSBFo) Lex Friedman did with Brian Kernighan. For those of you who are don't know [Brian Kernighan](https://en.wikipedia.org/wiki/Brian_Kernighan), he is a professor of computer science at Princeton University. He also co-authored the C Programming Language with Dennis Ritchie (creator of the C programming language). During the interview, they discussed [awk](https://en.wikipedia.org/wiki/AWK), a programming language that was co-created by Brian Kernighan. They mentioned that awk was an incredibly handy language to use when all you want to do is some simple data processing, exploration or extraction with small text files. That quickly piqued my interest, and so I decided to spend some time to figure out just how great awk is. I then started reading The AWK Programming Language (co-authored by Kernighan) and it wasn't long before I was convinced that awk is indeed a language worth learning! I found it incredibly simple to learn, and as it turns out we can do pretty interesting things with awk with only very little knowledge of it. The purpose of this post is simply to give you a taste of how simple and powerful awk is, and hopefully by the end of this post, you too will be convinced to learn it :) .

## Quick tutorial

For the purpose of this tutorial, I got my hands on this [small dataset](https://www.kaggle.com/hananxx/gamestop-historical-stock-prices) from Kaggle, it contains the historical prices of Gamestop Corporation ($GME). To make things easier, I will take just work with the last 5 lines of the dataset. Since the whole idea about using awk is use to eventually write one-liners to carry out simple tasks, I will be including simple yet handy code snippets like the below even if they are not awk related just in case you didn't already know about them. Lines that start with `$` are inputs to the shell, we only need to feed the shell what comes after the `$`. Whereas lines that do not begin with `$` are the outputs.

{% highlight bash %}
$ tail -5 GME_stock.csv > GME_stock_tiny.csv
{% endhighlight %}

Here's what we have in the `GME_stock_tiny.csv` text file

{% highlight csv %}
2002-02-20,9.600000381469727,9.875,9.524999618530273,9.875,1723200.0,6.648838043212891
2002-02-19,9.899999618530273,9.899999618530273,9.375,9.550000190734863,1852600.0,6.43001651763916
2002-02-15,10.0,10.024999618530273,9.850000381469727,9.949999809265137,2097400.0,6.69933557510376
2002-02-14,10.175000190734863,10.194999694824219,9.925000190734863,10.0,2755400.0,6.73300313949585
2002-02-13,9.625,10.0600004196167,9.524999618530273,10.050000190734863,19054000.0,6.766665935516357
{% endhighlight %}

Note that the headers are not present in the resulting file, this makes it slightly easier to illustrate the things that we can do in awk. Here are the headers `date`, `open_price`, `high_price`, `low_price`, `close_price`, `volume`, `adjclose_price`.

### Simple print
The first thing that I want to show you is how we can print only certain columns of each row, let's say we only want the `date` and the `high_price`, i.e. the 1st and 3rd columns, we do the following.

{% highlight bash %}
$ awk -F "," '{ print $1, $3 }' GME_stock_tiny.csv
2002-02-20 9.875
2002-02-19 9.899999618530273
2002-02-15 10.024999618530273
2002-02-14 10.194999694824219
2002-02-13 10.0600004196167
{% endhighlight %}

Now, I will explain what just happened here. We tell awk that the columns are separated by commas with `-F ","`, the `F` here means `field separator`. The default field separator that awk recognises is a space, which means that if the fields in your text file are separated by spaces, we may omit the format when executing awk. `'{ print $1, $3 }'` is basically the entirety of the awk script, which tells awk quite simply to print the 1st and 3rd fields of each row. Simple, isn't it?

### Doing computation
Of course, one would usually want to do some computation based on the fields that exist in each row, what if we wanted to get the average of the `high_price` and the `lower_price`?

{% highlight bash %}
$ awk -F "," '{ print $1, ($3 + $4)/2 }' GME_stock_tiny.csv
2002-02-20 9.7
2002-02-19 9.6375
2002-02-15 9.9375
2002-02-14 10.06
2002-02-13 9.7925
{% endhighlight %}

Quite simple, no? I hope that awk is starting to feel more and more intuitive.

### Adding strings to the output
It would be rather dull if we could only print things that are already within the fields, we can actually spice things up by adding some strings to the output.
{% highlight bash %}
$ awk -F "," '{ print "Date:", $1, "High Price:", $3, "Low Price:", $4 }' GME_stock_tiny.csv
Date: 2002-02-20 High Price: 9.875 Low Price: 9.524999618530273
Date: 2002-02-19 High Price: 9.899999618530273 Low Price: 9.375
Date: 2002-02-15 High Price: 10.024999618530273 Low Price: 9.850000381469727
Date: 2002-02-14 High Price: 10.194999694824219 Low Price: 9.925000190734863
Date: 2002-02-13 High Price: 10.0600004196167 Low Price: 9.524999618530273
{% endhighlight %}

#### printf
We can imagine things getting a even messier if we try to further customise the output. Good news is `printf` exists in awk! 

{% highlight bash %}
$ awk -F "," '{ printf("Date: %s, High Price; %.2f, Low Price: %.2f\n", $1, $3, $4) }' GME_stock_tiny.csv
Date: 2002-02-20, High Price; 9.88, Low Price: 9.52
Date: 2002-02-19, High Price; 9.90, Low Price: 9.38
Date: 2002-02-15, High Price; 10.02, Low Price: 9.85
Date: 2002-02-14, High Price; 10.19, Low Price: 9.93
Date: 2002-02-13, High Price; 10.06, Low Price: 9.52
{% endhighlight %}

Those of you who are familiar with `C` already know what's going on here. We basically get to define the format of the output in one piece `"Date: %s, High Price; %.2f, Low Price: %.2f\n"` by using `%s` and `%.2f` as placeholders. `%s` is a placeholder for strings and `%.2f` is a placeholder for floats (with 2 decimal places). We specify that we want `$1`, `$3`, and `$4` to take the place of the placeholders in the final output, things are a lot neater this way. Note that we added a newline `\n` at the end, something that `print` usually does for us by default.

### Selection
Let's say we want to exclude certain rows, here an `if` statement comes to mind. We shall do what we did above, but we only want to include rows where the `close_price` (the 5th field) is greater than or equal to 10. Here's how we can do it
{% highlight bash %}
$ awk -F "," '$5 >= 10 { print $1, $3, $5 }' GME_stock_tiny.csv
2002-02-14 10.194999694824219 10.0
2002-02-13 10.0600004196167 10.050000190734863
{% endhighlight %}

All we had to do was add a simple condition before the braces! As you can probably tell, the condition is optional, if we do not intend to filter any rows out we can simply omit it.

### Regex
Sometimes, we want to include certain rows only if they match some regular expression. For instance, if we want to include rows of the date range `2002-02-13` - `2002-02-15` using the regex `/2002-02-1[345]/`

{% highlight bash %}
$ awk -F "," '/2002-02-1[345]/' GME_stock_tiny.csv
2002-02-15,10.0,10.024999618530273,9.850000381469727,9.949999809265137,2097400.0,6.69933557510376
2002-02-14,10.175000190734863,10.194999694824219,9.925000190734863,10.0,2755400.0,6.73300313949585
2002-02-13,9.625,10.0600004196167,9.524999618530273,10.050000190734863,19054000.0,6.766665935516357
{% endhighlight %}

You might have noticed that the braces are missing inside the script, this is because awk prints the entire line by default. We can also refer to the entire line with `$0`, meaning that we could have achieved the same results by doing the below
{% highlight bash %}
$ awk -F "," '/2002-02-1[345]/ { print $0 }' GME_stock_tiny.csv
2002-02-15,10.0,10.024999618530273,9.850000381469727,9.949999809265137,2097400.0,6.69933557510376
2002-02-14,10.175000190734863,10.194999694824219,9.925000190734863,10.0,2755400.0,6.73300313949585
2002-02-13,9.625,10.0600004196167,9.524999618530273,10.050000190734863,19054000.0,6.766665935516357
{% endhighlight %}

### BEGIN / END
#### Begin
Up until now, we have only seen actions that we carry out on each line in our input file. We can actually execute code before and after iterating through each line. Suppose that we want to print out a header of sorts before printing out each line

{% highlight bash %}
$ awk -F "," 'BEGIN { print "Date       High Price" } { print $1, $3 }' GME_stock_tiny.csv
Date       High Price
2002-02-20 9.875
2002-02-19 9.899999618530273
2002-02-15 10.024999618530273
2002-02-14 10.194999694824219
2002-02-13 10.0600004196167
{% endhighlight %}

Which basically means that we can specify some code that we want to run at the **beginning** of the execution of the script.

#### End
We can also specify some code that we would like to execute at the end of the script, like so
{% highlight bash %}
$ awk -F "," 'BEGIN { print "Date       High Price" } { print $1, $3 } END { print NR, "rows processed" }' GME_stock_tiny.csv
Date       High Price
2002-02-20 9.875
2002-02-19 9.899999618530273
2002-02-15 10.024999618530273
2002-02-14 10.194999694824219
2002-02-13 10.0600004196167
5 rows processed
{% endhighlight %}

`NR` is a variable that tells us the number of the current row being processed, and since we have reached the end of script `NR` still carries the value of the last row number.


### Variables
awk supports variables as well, and this is especially useful when we want to print out some summary of our data. Suppose that we would like to calculate the average `open_price`, it would make sense for us to have some kind of variable to sum up the `open_price` of each individual row, and then when we reach the end of the script, we can print out `open_price` divided by the number of rows using `END`.
{% highlight bash %}
$ awk -F "," '{ total_open_price = total_open_price + $2; total_close_price = total_close_price + $5 } END { print "Average open price is", total_open_price/NR; print "Average close price is", total_close_price/NR }' GME_stock_tiny.csv
Average open price is 9.86
Average close price is 9.885
{% endhighlight %}

For each row, we override the `total_open_price` with the previous `total_open_price` and the `open_price` of the current row. Note that we don't have to initialise or declare the variable beforehand since it is initialised implicitly to 0. Here we also take note of the fact we can have more than one statement in each block, we just need to separate them with colons.

### If statements
Now what if we would like to do something different on each row based on the data that we encounter within it? Here's where if statements come in. Now, the commands in this section and some of the following ones do not quite fit on a single line, but I decided to include them here for completeness. awk scripts are not always one liners, we always have the option of writing out the entire script and placing it in a file and only then executing it, but I will not go through this option here.

Suppose we just want to print a different message if the volume on a particular day exceeded 2000000.

{% highlight bash %}
$ awk -F "," '{ printf("Date: %s, Volume: %d", $1, $6); if ($6 > 2000000) { printf(" > 2000000\n") } else { printf(" < 2000000\n") } }' GME_stock_tiny.csv
Date: 2002-02-20, Volume: 1723200 < 2000000
Date: 2002-02-19, Volume: 1852600 < 2000000
Date: 2002-02-15, Volume: 2097400 > 2000000
Date: 2002-02-14, Volume: 2755400 > 2000000
Date: 2002-02-13, Volume: 19054000 > 2000000
{% endhighlight %}

### How to write the output to a file
Just in case you didn't know how to do this, I thought that it'd be relevant to mention how you can create a new file to hold the output of your awk script (I am not sure if this works on Windows but it should definitely work on a Mac/Linux machine).

{% highlight bash %}
$ awk -F "," '{ print $1, $3 }' GME_stock_tiny.csv > GME_stock_mini.txt
{% endhighlight %}

And the output will be found in a newly created file called `GME_stock_mini.txt`.

## Conclusion
I hope that the above gave you a taste of what's possible with awk! The above examples barely scratch the surface of what one can do with awk, if you want to learn more about it feel free to check out the book I mentioned earlier. awk is perfect when all you need is a short script to explore some data that you have at hand. If I didn't know about awk, I would probably do something similar with the `pandas` library in Python, which would probably take more work.

Kernighan did an [interesting lecture](https://www.youtube.com/watch?v=Sg4U4r_AgJU&t) at Nottingham University where he presented audience with a simple problem. Imagine that we have thousands of lines of data in the below form.
```
8/27/1883    Krakatoa        8.8 
5/18/1980    MountStHelens   7.6 
3/13/2009    CostaRica       5.1 
```

The data shows seismic events along with their corresponding magnitudes. How would one extract rows with magnitudes greater than 6? He showed us his attempt to solve the problem in C and it looks like the below.

```c
#include <stdio.h> 
#include <string.h> 

int main(void) {   
    char line[1000], line2[1000];   
    char *p;   
    double mag;   
    while (fgets(line, sizeof(line), stdin) != NULL) {     
        strcpy(line2, line);     
        p = strtok(line, "\t");     
        p = strtok(NULL, "\t");     
        p = strtok(NULL, "\t");     
        sscanf(p, "%lf", &mag);     
        if (mag > 6)   /* $3 > 6 */       
            printf("%s", line2);   
    }   
    return 0; 
} 
```

The awk equivalent is of course a lot simpler, it'd look something like the below.
```awk
$3 > 6
```

And this clearly illustrates the fact that they are usually many ways to solve a problem, and it is important to choose the right tool to simplify the task at hand, I am sure awk will be a tool that comes in handy one day for you.