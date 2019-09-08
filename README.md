# Project 1: Vampire Numbers
  
**This program takes in a lower and upper bound to search through for vampire numbers. It divides the given range into sub-ranges that are distributed to worker nodes and managed by a supervisor and multiple GenServers.**  

## Running the program

To run use the command:  

```mix run proj1.exs start end```

where **start** and **end** are both integers that comprise the range that you wish to search for vampire numbers.

## Performance

In order to determine the amount of work to give each worker, I used the **UNIX time function** on my MacBook and **compared the CPU time to real time**, adjusting until I saw the best results.

I found that for my laptop,  spawning **8 worker GenServers** proved to be the most efficient, despite having only 4 real cores, due to the 4 additional virtual cores my MacBook utilizes through hyper threading.

**Similarly, I had each of the 8 workers do 1/8 of the total range of vampire numbers**. This works best for the general case where your range of total numbers does not extend between numbers of different lengths. For instance, each worker will do the same amount of work as long as the range is a subset of 1000-9999 or a subset of 100000-999999 and so on. A further optimization would be to have work be determined also by the size of the numbers a given worker is computing (i.e. if the range is 1000-200000, the first worker could be given all the 4 digit numbers as they will still finish before the workers who do the 6 digit numbers)




 *CPU usage via :observer.start, running the range 100000 - 200000*
![](https://lh3.googleusercontent.com/Zttj_mAdYxSnPbHECg6b7nEIidLud7YIWYQQSnueSOp4gbAcopy1IRM-RJbIhArYhbmLpurlC7IF "CPU Usage With Observer")


Upon running ```time mix run proj1.exs 100000 200000``` the real time was **16.805s** while the CPU time was **2m8.348s**.
 It follows that the program produced a CPU utilization of 128.348/16.805 = **7.6374**. Which is pretty good considering there are only 4 real cores in my system.

Upon running ```mix run proj1.exs 100000 200000``` the output produced is:

146952 156 942
146137 317 461
145314 351 414
140350 350 401
186624 216 864
182650 281 650
182250 225 810
180297 201 897
180225 225 801
175329 231 759
174370 371 470
173250 231 750
172822 221 782
163944 396 414
162976 176 926
136948 146 938
136525 215 635
135837 351 387
135828 231 588
134725 317 425
133245 315 423
132430 323 410
131242 311 422
129775 179 725
129640 140 926
126846 261 486
126027 201 627
125500 251 500
125460 204 615 246 510
125433 231 543
125248 152 824
124483 281 443
123354 231 534
120600 201 600
118440 141 840
117067 167 701
116725 161 725
115672 152 761
197725 275 719
193945 395 491
193257 327 591
192150 210 915
190260 210 906
156915 165 951
156289 269 581
156240 240 651
153436 356 431
152685 261 585
152608 251 608
150300 300 501
110758 158 701
108135 135 801
105750 150 705
105264 204 516
105210 210 501
104260 260 401
102510 201 510

## Additional Notes

If more or less than 2 command line arguments are provided, or the first argument provided is larger than the second, a message is printed and the program terminates. 

If either of the arguments are a non-integer, a MatchError occurs and the program terminates. I chose not to handle this manually as this would be the expected behavior anyway.

Upon first completing this project, I had used a Task supervisor and an asynchronous stream to run 8 Tasks that compute the same function asynchronously. This solution was only 100 lines of code. I still believe Task is the appropriate elixir module to use for the given use case, because we are only looking to compute a single thing provided a range for each worker. The extra control GenServer provides is unneccesarry. 
I have gone ahead and included this script as **task_proj1.exs**. It can be run via ```mix run task_proj1.exs arg1 arg2```

That being said, I used the *Programming Elixir (1.6)* textbook to help me organize my project in a way that would support GenServers. The idea behind the solution is that each managing GenServer only has one responsibility. The program starts by creating a parent Supervisor with 4 children: The results tracking GenServer, the range provider GenServer, the result gathering GenServer and then the worker dynamic supervisor. This allows for fine control over how the program runs. The number of workers is provided to and tracked by the gatherer, which tells the worker supervisor to spawn the correct number of workers. Each worker than asks the range provider for a range to compute. Sending the resulting vampire numbers back to the gatherer. At the gatherer, the results are passed on to the results GenServer and the number of active workers is decreased by one. Once the number of workers is zero, the gatherer GenServer retrieves the results from the results GenServer and prints them. 

The main project Supervisor is set to have all 4 children terminate if any of them crash (one for all), as the system will not work without them all. The worker supervisor is set as one for one, letting the other workers finish even after a worker is complete. As long as the worker exits normally, the worker supervisor will not spin another worker up in its place (transient children). 

In order to have the mix run process wait for other processes to complete, I have it monitor the main supervisor until it sends a terminated signal. In deployment, using iex, or using the --no-halt flag, this would be a non-issue  as the main process runs until told to stop.
