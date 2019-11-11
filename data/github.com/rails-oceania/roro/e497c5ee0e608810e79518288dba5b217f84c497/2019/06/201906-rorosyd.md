theme: Poster
footer: @rorosyd @rubyaustralia
slidenumbers: true

# [fit] **Ruby on Rails**
# [fit] **_Oceania_**
# 11 June 2019

^
Welcome to RoRoSyd.

---

# [fit] **Tonight**
## *Talks*
## *Events / Tips / Jobs*
## *Pub*

^
Again tonight we have a great lineup of speakers, we'll cover some upcoming events, tips, tricks and jobs opportunities.<br />
Then it's off to the pub to continue the conversation.

---

# [fit] **Housekeeping**
### *Bathrooms*
### *Emergency Exits*
### *Hot food*
### *Glass bottles*

^
- Location of bathrooms
- Feel free to take any leftover food home with you
- Once you've finished your food and drinks, please be sure to put your plates and bottles in the bins provided.
- Please recycle all bottles in the tubs

---


# [fit] **Code Of Conduct**
# [fit] *`ruby.org.au/code-of-conduct`*
# [fit] *`ruby.org.au/committee-members`*
# [fit] *`conduct@ruby.org.au`*

^
If this is your first RORO, or if you were previously unaware, Ruby Australia events are run under a code of conduct.<br />
This is the link where you can find it and have a read, but in summary we want this meetup to provide a friendly and welcoming environment for everyone who attends, and harassment of any kind is not tolerated.<br />
If you have any issues you want to raise about anything that has happened at a RORO, you can talk to any of the organisers who are Paul and Rob, or you can go straight to a Ruby Australia committee member if you don't think you can reach out to a RORO organiser.<br />

---

# [fit] **Thanks** **_to our_**
# [fit] **Sponsors**

^
RORO has many sponsors, without which these meetups would not be possible.

---
[.background-color: #3D4A7E]
# [fit] **Venue Sponsor**
![inline 220%](https://www.dropbox.com/s/7h9sxdixw0kwzin/coder-academy-logo.png?dl=1)

^
So, a big thanks firstly to out venue sponsor Coder Academy. Coder Academy's mission is to promote equality and drive innovation via high quality technology training. Through a variety of tech training programs in Sydney, Melbourne, and Brisbane, Coder Academy equips Australians with the in-demand coding and technology skills they need to tackle the future of work.<br />

---
[.background-color: #3D4A7E]

# [fit] **Drinks Sponsors**
![inline 130%](https://www.dropbox.com/s/7h9sxdixw0kwzin/coder-academy-logo.png?dl=1)
![inline](https://www.dropbox.com/s/rtel8e4hy8d06kw/lookahead-logo.png?dl=1)

^
Next, your drinks are brought to you tonight by the combined powers of our venue host Coder Academy, and Lookahead Search: technical recruiters who are actually technical. And Lookahead are, literally, always hiring.<br />

---
[.background-color: #3D4A7E]

# [fit] **Food Sponsor**

![inline](https://www.dropbox.com/s/cxq6w0jx76jyc3x/ruby-au-logo.png?dl=1)

^
The bill for our dinner tonight gets sent to Ruby Australia, who organise sponsorship for all Ruby-related meet-ups around Australia.<br />
Their sponsors are our community sponsors, so we would like to thank...

---
[.background-color: #3D4A7E]

# [fit] **Community Sponsor**

<br />

![inline](https://www.dropbox.com/s/rt37lwsic8rw6h2/envato-logo.png?dl=1)

^
Envato: Leading marketplace for creative assets and creative people. Using Ruby: Always Hiring.

---
[.background-color: #3D4A7E]

# [fit] **Community Sponsor**

<br />

![inline](https://www.dropbox.com/s/rtel8e4hy8d06kw/lookahead-logo.png?dl=1)

^
Lookahead Search, Technical recruiters who are actually technical.

---
[.background-color: #3D4A7E]

# [fit] **Community Sponsor**

![inline](https://www.dropbox.com/s/h36hivrlykx4wbu/culture-amp-logo.png?dl=1)

^
Culture Amp, providers of Company Culture Analytics

---

# [fit] **TALKS**

---
[.hide-footer]
[.slidenumbers: false]

![left](https://www.dropbox.com/s/zbfesv4y3ob1ajj/tim-riley.jpg?dl=1)

# [fit] *A tour of*
# [fit] dry-schema *and*
# [fit] dry-validation 1.0
# [fit] **_Tim Riley_**
# [fit] **`@timriley`**

---
[.hide-footer]
[.slidenumbers: false]

![right](https://www.dropbox.com/s/098icz3exah32o7/richard-heycock.jpg?dl=1)

# [fit] *How to*
# [fit] debug
# [fit] *a* running process
# [fit] **_Richard Heycock_**
# [fit] **`@filterfish`**

---
[.hide-footer]
[.slidenumbers: false]

![left](https://www.dropbox.com/s/252dog4ynjo68xl/sean-mccartan.jpg?dl=1)

# [fit] *The* Future *of*
# [fit] Ruby on Rails
# [fit] **_Sean McCartan_**
# [fit] **`@The_Onset_`**

---
[.hide-footer]
[.slidenumbers: false]

![right](https://www.dropbox.com/s/97od5uuztnn9tse/ewe-lin.jpg?dl=1)

# [fit] *Exercism:*
# [fit] Acronym
# [fit] **_Ewe Lin_**
# [fit] **`@ewelinloo`**

---
![inline 4%](https://www.dropbox.com/s/6lcxixt3dtsiw3g/Twitter_logo_bird_transparent_png.png?dl=1)

# [fit] `@timriley` */* `@filterfish`
# [fit] `@The_Onset_` */* `@ewelinloo`
# [fit] *`@rorosyd`*

^
If you're Twitter-inclined please let tonight's speakers know how much you appreciate the work they put in by tweeting about it. Giving feedback definitely makes the speakers feel their efforts have made an impact beyond building their own presentation portfolio. Don't forget to mention rorosyd to tie the night altogether. 

---

# [fit] *Who's* **New?**
# [fit] *Say* **Hello!** :wave:

^
So if you're new to Roro can you please put up your hand, don't worry we're not going to make you stand up or say anything.  Everyone have a look around at any new people standing near you with their hands up. We're going to have a 5 minute break, so please welcome them, and we'll kick off the talks.

---

# [fit] *Next Meetup's* Exercism
# [fit] **Raindrops**

# [fit] *`exercism download --exercise=raindrops --track=ruby`*

^
Convert a number to a string, the contents of which depend on the number's factors.<br />
If the number has 3 as a factor, output 'Pling'.<br />
If the number has 5 as a factor, output 'Plang'.<br />
If the number has 7 as a factor, output 'Plong'.<br />
If the number does not have 3, 5, or 7 as a factor, just pass the number's digits straight through.<br />
As always you can find more details and download the challenge at the exercism.io and it you'd like to present your solution at next months meetup submit an issue on the RORO github or contact myself or one of the other organisers. 

---

# [fit] **Thank you!**

^
Thanks so much to all the speakers tonight, and if anyone is interested in giving a talk at a future RORO...

---

# [fit] *We are always looking for*
# [fit] **SPEAKERS!**

^
We are looking for speakers!
- We want *you* to present something at RORO because presenting at RORO is a win/win situation. You, the speaker, practice a skill and learn new things, and we, the audience, leverage your knowledge to learn new things that can potentially help us.<br />
- It's great public speaking practice in front of an audience that wants you to succeed because we're all here to learn cool new things, and...<br />
- Any talk you present here is great fodder for your resume and portfolio, and just by virtue of presenting, everyone will think you're an expert, which will surely lead to at least an endorsement on LinkedIn<br />
- So if you've got something to say, or to show and tell, that you think the Ruby community would love to hear about...

---

# [fit] **Where do I sign up?**

- :globe_with_meridians: *`github.com/rails-oceania/roro/issues`*
- _`@paulfioravanti`_
- _`@robcornish`_
- *:email: `rorosydmeetup@gmail.com`*

^
- Open up an issue at the RORO Github repo and tell us about the talk you want to submit, or feel free to message any of the organisers.<br />
- The repo has presentation requests added, so check them out if you're looking for an idea to do a talk about.
- Remember, It is *good* to throw yourself out of your comfort zone and try
something different, and who knows, you might even end up liking it and wanting
to do more.<br />
- Also, if you need any help creating or critiquing your presentation or want someone to do a dry run, then please feel free to approach any of the RORO organisers and we're happy to help you in any way we can to make you look awesome up on stage.

---

# [fit] *We are always looking for*
# [fit] **VENUES!**

^
We are now also always looking for venues! If you or your company think you would like to give hosting a RORO meetup a shot, Rob and I would love to hear from you.<br />
There are no obligations, strings attached, or guilt-trips given about hosting RORO regularly, or even more than once. Maybe your company is meetup-curious and just wants to give it a try, or maybe your company is bursting with VC-funding and wants to host *every* meetup in its resort office until the runway is dry. Whatever the case, if you are interested, please reach out to the RORO organisers.

---

# [fit] **NEWS**

---

# [fit] Ruby *2.7.0-preview1*
# [fit] **Released**

- *`https://www.ruby-lang.org/en/news/2019/05/30/ruby-2-7-0-preview1-released/`*

^
Includes a number of experimental features like pattern matching, an improved IRB console, beginless ranges amongst other things, so if you want to get a sneak peek at the potential future of Ruby, use your Ruby version manager of choice to download and check out this preview release.

---

# [fit] Opal *1.0*
# [fit] **Released**

- *`http://opalrb.com/blog/2019/05/12/opal-1-0/`*

^
Opal is a Ruby to JavaScript source-to-source compiler, so if you really don't like Javascript or you just want to write absolutely everything in Ruby, then you can use it to write your front-end code in Ruby.<br />
We have not had a presentation about it yet, so there is a presentation request in the RORO Github repo about it, so if you want to become the resident community expert in Opal, you could probably do it by presenting an Opal Hello World.

---

# [fit] *Future* Mac OS versions *to*
# [fit] not *include* Ruby

- *`https://developer.apple.com/documentation/macos_release_notes/macos_10_15_beta_release_notes#3318257`*

^
Future versions of Mac OS will not be bundled with scripting languages like Ruby. Not sure of anyone who actually uses the system version of Ruby for anything, and doesn't use a Ruby version manager of some kind (rvm, rbenv, chruby, asdf etc), so hopefully this shouldn't be an issue for most developers.

---

# [fit] **_Upcoming_**
# [fit] **Events**

---

# [fit] **RubyConf** *Taiwan*

### July 26 - 27 2019
### *`https://2019.rubyconf.tw/`*

^
No domestic events for the coming months, but if you're looking for a reason to go overseas, then RubyConf Taiwan is happening on July 26-27, and as well as a great line-up of international speakers, you will also find Adelaide Ruby developer Yuji Yoko doing a talk about developing games for the Sega Dreamcast using mRuby. mRuby being a lightweight implementation of the Ruby language, complying with part of the ISO standard, that can be linked and embedded within an application. We have a presentation request for someone to teach us all about mRuby, so if you are that person, please take up that issue on the RORO repo.

---

# [fit] **Tips and Tricks**
# [fit] _Stuff that makes your life_
# [fit] _easier/better/faster_

^
[Anything speakers want to add...?]

---

# [fit] **JOBS**
# [fit] *Offering work?*

^
Offering: say your name, your company name, a sentence on what you do. And a sentence on who you're looking for - juniors, mids, seniors etc

---

# [fit] **Slack/Forum**
## [fit] *- `ruby-au-join.herokuapp.com`*
## [fit] *- `forum.ruby.org.au`*

---

### [fit] **Twitter:** *`@rorosyd`, `@rubyaustralia`*
### **Web:** *`ruby.org.au`*
### **Google group:** *`rails-oceania`*

---

# [fit] *Next Meetup*
# [fit] 9 July 2019
# [fit] **_\(2nd Tuesday of the month\)_**
# [fit] *at* FluidIntel

^
The next meetup will be the 9th of July at Rob's home turf of FluidIntel, located at 111A Union St, McMahons Point. No need to remember that now as it will be in the details for the next meetup, but thanks to FluidIntel for hosting our next meetup!

---

# [fit] **And Now...**
# [fit] *Pub (Firehouse)* :beer:
# [fit] *Gelato (Gelatissimo)* :ice_cream:

^
Please make sure to clean up after yourself and put your plates in the rubbish bins and empty bottles in the recycling bins. Thanks for coming along and we hope to see you next month!
