---
layout: post
title: "On services."
date: 2018-10-12 18:00:00 +100
comments: false
---

## On services

<!--excerpt-start-->

I'm not really a fan of services, that is classes in your code base which are 
named something service. While I'm happy to admit that sometimes they do have 
a place much of the time when I see a class named something service, it has 
usually served as a dumping ground for business logic which someone couldn't
find a better place for. I too have fallen into this trap, so spurred on by a 
twitter thread posted in response to [this article by Frederick Vanbrabant](https://frederickvanbrabant.com/post/2018-10-08-integration-operation-segregation-principle/)
I decided to write up a few thoughts.

<!--excerpt-end-->

The article starts off with the following code example:

```php 
<?php
declare(strict_types=1);

namespace Car\Rent;

final class PriceCalculator
{
    public function calculate(CarRental $carRental): int
    {
        $startDate = $carRental->getStartDate();
        $endDate = $carRental->getEndDate();
        $days = $startDate->diff($endDate);
        $dayPrice = $days * $carRental->getPricePerDay();

        return $dayPrice + ($carRental->getDistance() * $carRental->getPricePerKm());
    }
}
```

and goes on to show a test, the test shows mocking of the CarRental object shown
as a parameter along with expectations and discusses how this test is quite complex.
None of this I disagree with, however the direction taken afterwards is different 
to what I would do. 

First of all, I wouldn't bother mocking the CarRental object 
in a test, I'm assuming it's a value object and in most cases, mocking value objects
is more complex than just using the original object, however this is a subject for
another post. My test would be something like:

```php 
<?php
declare(strict_types=1);

namespace Tests\Car\Rent;
use Car\Rent\CarRental;
use Car\Rent\PriceCalculator;

class PriceCalculatorTest extends TestCase
{
    /**
     * @test
     */
    public function it_calculates_a_price()
    {
        $carRental = new CarRental(...);
        $calculator = new PriceCalculator();
        $price = $calculator->calculate($carRental);

        $this->assertSame(110, $price);
    }
}
```

My first step in refactoring this service class would be to move logic into a more
suitable class, in the code above, the PriceCalculator service first retrieves a 
start and end date and then performs a calculation on them. Let's move that somewhere
better.

```php 
<?php
declare(strict_types=1);

namespace Car\Rent;

final class CarRental
{
    private $startDate;
    private $endDate;
    private $distance;
    private $pricePerDay;
    private $pricePerKm;
    
    public __construct(...) {}
    
    public function getDays() 
    {
        return $this->startDate->diff($this->endDate);
    }
}
    
```
 
 Our calculator service then simplifies to:
 
 ```php 
 <?php 
 declare(strict_types=1);
 
 namespace Car\Rent;
 
 final class PriceCalculator
 {
     public function calculate(CarRental $carRental): int
     {
         $dayPrice = $carRental->getDays() * $carRental->getPricePerDay();
 
         return $dayPrice + ($carRental->getDistance() * $carRental->getPricePerKm());
     }
 }
 ```
 
 Interestingly, our test doesn't need to change. 
 
 You could then go on to perform the same refactoring that Frederick does in 
 order to further simplify the service class however you have just moved some
 logic from a service to a value object, why stop there? We are starting to 
 question if we need the service class at all.
 
 Often when I ask people why some logic exists in a service class instead of a
 value object or entity, the answer is usually so we can change it. This implies
 that there are multiple possible implementations for a price calculator - perhaps
 a different method to calculate a price based on different contracts. A service
 could make sense here - it can look up the correct business rules to apply in a 
 given case and apply them but perhaps we are missing a concept in our domain.
 
 In this case, perhaps it is a pricing scheme. Immagine our rental firm has a 
 fixed term rental and an open ended rental, under the open ended rental, you 
 pay a higher price per km, but the daily fees stop after the first 7 days. The
 fixed term rental features a lower price per km but charges a penalty fee if 
 the car is returned late.
 
 We may end up with a model something like:
 
 ```php
<?php
declare(strict_types=1);

namespace Car\Rent;

final class CarRental
{
    private $startDate;
    private $endDate;
    private $distance;
    private $pricingScheme;
    
    
    public __construct(...) {}
    
    public function getDays(): int 
    {
        return $this->startDate->diff($this->endDate);
    }
    
    public function getPrice(): int
    {
        return $this->pricingScheme->getPrice($this->getDays(), $this->distance);
    }
}

final class OpenEndedPricingScheme implements PricingScheme
{
    private $pricePerKm;
    private $pricePerDay;
    private $maxDailyCharges;
    
    public function getPrice(int $days, int $distance): int
    {
        return (min($days, $this->maxDailyCharges) * $this->pricePerDay) + ($distance * $this->pricePerKm);
    }
}

 ```
 
 We've done away with the need for the service class by building a richer set 
 of value objects and by putting the logic with the data it's easier for us to
 reuse the logic in a number of places. By encapsulating this knowledge of how
 to calculate a price into the value objects we make it easier to change the
 logic without impacting upon consumers of the value object.
 
 ### Conclusion
 
 It's fairly easy to fall into the trap of using services to contain business 
 logic, I myself have done this for example the 
 [Ticket Availability service](https://github.com/conferencetools/tickets-module/blob/master/src/Domain/Service/Availability/TicketAvailability.php) in
 my ticketing application, this service started out with the logic to handle 
 availability of different ticket types and grew as more rules were added about
 which tickets were available. This then got refactored in a way not too dissimilar
 to the article at the top of this page to reduce the complexity of each class.
 However as I continued to work with the code I realised the reason that the
 service, now spread across multiple classes was had become so complex was that
 I was missing an important domain concept: Tickets have a life span and their
 status changes over time. My current refactoring of the ticketing system to 
 bring it onto newer versions of it's library code has also allowed me to rethink
 the model and bring the logic once contained in a service class into an aggregate.
 
 I'm not suggesting that you should get rid of all service classes, they still have
 a place, however next time you are thinking about refactoring one; ask yourself
 is there a better place to put this logic? Are we missing a concept in our domain
 model.  