---
layout: post
title: "Stop lying to me"
date: 2015-08-16 10:00:00 +100
comments: false
---

## Lies, damned lies and hidden dependencies

As a developer, one of the things which consistently annoys me is hidden/none obvious dependencies. There are a number
of reasons this annoys, me for starters it can really slow down writing tests [(for example)](http://misko.hevery.com/2008/08/17/singletons-are-pathological-liars/)
when you have to manually trace through an object graph to figure out what you need to mock out. This need for manual
tracing also impairs cognitive understanding increasing the time it takes to understand what is happening and quite often
prevents your expensive IDE from helping you out. Code with hidden dependencies also has a high resistance to change with
unintended consequences to minor edits popping up in seemingly unrelated areas.

## Some examples

So here are some examples from popular frameworks of what I'm talking about:

```
<?php

namespace App\Http\Controllers;

use App\User;
use App\Http\Controllers\Controller;

class UserController extends Controller
{
    /**
     * Show the profile for the given user.
     *
     * @param  int  $id
     * @return Response
     */
    public function showProfile($id)
    {
        return view('user.profile', ['user' => User::findOrFail($id)]);
    }
}

```

Here the code calls a static method on the User model to find a user by it's id; we can assume that this will be loaded
from some sort of persistent data source which will also accessed statically building a mountain of global state.

```
<?php

namespace Blog\Controller;

use Zend\Mvc\Controller\AbstractActionController;
use Zend\View\Model\ViewModel;

class ListController extends AbstractActionController
{
    public function indexAction()
    {
        return new ViewModel(array(
            'posts' => $this->getServiceLocator()->get('postService')->findAllPosts()
        ));
    }
}
```

Here is another example of a hidden dependency, this time cleverly disguised inside a service locator. Admittedly, the
documentation for the above framework now demonstrates proper dependency injection however [it was not always this way](http://framework.zend.com/manual/2.2/en/user-guide/database-and-models.html)
as such there is a lot of code and developers in the wild which still hide dependencies in service locators.

```
<?php
namespace Blog\Controller;

use Blog\Service\PostServiceInterface;
use Zend\Mvc\Controller\AbstractActionController;
use Zend\View\Model\ViewModel;

class ListController extends AbstractActionController
{
    /**
    * @var \Blog\Service\PostServiceInterface
    */
    protected $postService;

    public function __construct(PostServiceInterface $postService)
    {
        $this->postService = $postService;
    }

    public function indexAction()
    {
        return new ViewModel(array(
            'posts' => $this->postService->findAllPosts()
        ));
    }
}
```

Above is another example, from the same framework as the previous example, this time however the dependency is injected
in the constructor making it explicit and far easier to trace.

From the trivial examples here it can be hard to see the benefits, however in a longer method which handles input processing,
fetching or saving of data and conditional redirect logic, dependencies in the form of the first and second examples can
be hard to keep track of or spot amongst the logic of the application code. Mixing different types of logic (presentation
and wiring logic in our case) in the same class will eventually lead to problems once the software becomes complex.

## Conclusion

The code above is a symptom of rapid application development practices, it may seem attractive (especially to the business side)
to be able to develop systems quickly, however this is a price which will almost always have to be paid back further down
the line in increased maintenance costs. Blurring boundaries between dependencies speeds development, but harms future
development as you untangle the spiders web. On the other hand following a stricter approach to dependencies may take
longer to start with as you have to write additional factory classes, however the benefits are realised further down the
line as the barrier to change is lowered.

### Credits

Example 1 comes from the [Laravel documentation](http://laravel.com/docs/5.1/controllers)

Example 3 comes from the [Zend framework documentation](http://framework.zend.com/manual/current/en/in-depth-guide/services-and-servicemanager.html)

Both are reproduced here to provide context to my critique of certain development practices.