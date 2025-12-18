## Sync Actions

### Lazy Syncing
- when the client goes to different screens, like all projects, a project, or the projects images, or fabrics, it will check if it needs to sync data with the server
- it won't be checked until you go to these screens and might potentially do a full sync for related tables
- this should be resumeable ideally, especially with images

### Eager Syncing
- will be done through websockets
- when a client is connected, it pushes events to the server
- data will be updated in the database and only if it is successful will the event be sent to connected
clients
- the events will also be stored as is in the database in one table
- any other connected clients will receive the events and update their local database accordingly
and return acknowledgement that it was stored successfully

## Deletes
- deletes should be soft deletes on the server, up to a certain time point otherwise if a user hasn't done a sync for a table in a while then a full sync is necessary

## Potential Problems with syncing
- if a user is using multiple devices, they update one device which updated the database schema, but their other device(s) haven't updated. If the
updated device pushes new events to the server the other devices that don't support the new schema will have problems syncing. Will need to add versioning
to each database schema update. 
- So each event will have the version of the database for the app. 
- If a version is greater than the version on the app the app will ignore it
- if an older version pushes an event, but the newest version of the database doesn't support that event anymore will need to figure out what to do there
  - I can consider making the database fully backwards compatible and just soft deprecate columns or tables
  
@Environment
- this is used to dismiss a view, among other things, if you want to do it programmatically (lesson 36, showing and hiding views)

## Animations
- Project 6 is all about animations, look at this later when learning about animations


## Classes
- add @Observable to classes to tell swift to track the variables like they do in structs with @State, lesson 36
## Lists
- adding delete functionality, native, lesson 36, deleting items
- 

## User settings
- storing settings with `userdefaults`, lesson 36, storing user settings
    - userdefaults is good for simple user data
    - like the theme, maybe a view layout, just a simple key value store 
    - lesson that uses codable, lesson 36, information on how to convert structs to JSON and other types

## Images
- resizing them to fit available space, lesson 39
- 

## Scrolling
- virtual scrolling, lesson 39, use Lazy Hstack and Vstack

## Navigation
- lesson 43, has more information to lazy load views when a navigation view is clicked
- apparently if you specify a view to display when using `navigationLink` it will get immediately created which can be costly in a list view
- can store navigation stack on device and restore it later
- can also store `codable` navigation paths, basically if they can be serialized then its possible to store more complex data than simple arrays (lesson 44)
- navigation title can be made editable (lesson 45)

`@Binding`
- to use two way binding in your own custom view

## Warnings
### List
- do not mix list views that only use strings array as the backing data type
- it seems if you use the string in an editable text field then if all your textfields are empty and you try to modify them, they will get rerendered and the other textfields that are empty will take focus, because in swift's view the now not empty textfield isn't the same anymore and it moves you to the next empty textfield because it thinks that's what 
- basically the id of an empty text field is an empty string and if you have many of them, if you modify one, it's id will change but swift i guess tries to make keep you on focus on a textfield with the same empty string id
- the solve the issue the backing data need to have stable/unique ids, so you can use incrementing number or uuid

### Warning
- deleting a textfield that is binded, especially in a List view or Foreach will cause a crash with index out of bound
    - usually i can get this crash if i swipe delete the item the textfield that is focused
    - if the textfield isn't focused then it should be fine

## Debugging Tests
#### UI Test Recorder
1. Click inside test
2. click on the red circle on the bottom of the code
3. tap around in simulator and see the updated code

#### Accessibility Inspector
1. Click on Xcode > Open Developer Tool > Accessibility Inspector
2. Select simulator as the target being inspected
3. Now can select Inspection follows point and hover it over the elements on simulator screen

#### iOS App debugging with po
1. create a debug point in the test
2. run the test and it will stop at the breakpoint
3. you can run po commands in the console where (lldb) is
4. with this you can filter out elements and get their descriptions

## Alerts
- can potentially only have one alert per view?? Will have to investigate this
    - can maybe look at this link to solve the problem https://stackoverflow.com/questions/58069516/how-can-i-have-two-alerts-on-one-view-in-swiftui
    - https://www.hackingwithswift.com/quick-start/swiftui/how-to-show-multiple-alerts-in-a-single-view
- I tried to have two different alerts that I thought modified the buttons they were attached to
    but swiftui only displayed the first defined alert(attached to the save button) and ignored the second one(the one on the back button)

### Dates
- have to compare dates with a specific granularity because the data accuracy isn't guaranteed
- it's possible to get the current with Date() and save it in the database, however the value from Date() might end up different when you retrieve it from the database due to accuracy lost
- more info here: https://github.com/groue/GRDB.swift/issues/492

### Fonts
- roboto
- montserrat
- josefi

## Removing focus from textfield when clicking outside of it
- https://gist.github.com/arthmis/92c46c46dd448b5a527e68c13a1bc715
- https://www.reddit.com/r/swift/comments/14icasf/remove_automatic_focus_on_textfield_swiftui/ (original)

## conditional view modifiers
- https://www.objc.io/blog/2021/08/24/conditional-view-modifiers/
- cause bad animatinos and potentially wonky behaviors because swift treats the two returned views as entirely different views and is unable to understand that they represent the same thing
- also causes state to be lost because the separate branch is treated as a new view

## share extensions for ios App
- it seems that when running a share extension and you select an app to open:
  - if you run a different app without closing the current host app for the extension then the 2nd app you run will not display your ios app as a choice for sharing
  - you must first close the original app opened by running the share extension
  - for example if you run the extension and open safari, subsequent runs where you choose safari and didn't stop the run with the stop button you will continue to see your app as a choice amongst the selection
  - another example, if you run safari for the extension, you don't hit stop, you run a different app, like photos, the photos app will not show your app as a choice until you stop the original safari invocation and any subsequent ones
