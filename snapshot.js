var target = UIATarget.localTarget();
var window = target.frontMostApp().mainWindow();

if (isTablet()) {
  target.setDeviceOrientation(UIA_DEVICE_ORIENTATION_LANDSCAPELEFT);
}

target.frontMostApp().setPreferencesValueForKey("quality", "sorting");

setUser("koraktor")
settings();
games();
csgo();
tf2();
setUser("king2500")
dota2();

function setUser(user) {
  if (target.frontMostApp().navigationBar().leftButton().isEnabled()) {
    if (target.frontMostApp().preferencesValueForKey("SteamID") == user) {
      return;
    }

    target.frontMostApp().navigationBar().leftButton().tap();
    target.delay(1);
    window.textFields()[0].setValue("");
  }

  target.frontMostApp().keyboard().typeString(user + "\n");
  target.delay(10);
}


function games() {
  captureLocalizedScreenshot("games");
}

function settings() {
  target.frontMostApp().navigationBar().rightButton().tap();
  target.delay(1);

  captureLocalizedScreenshot("settings");

  if (isTablet()) {
    target.frontMostApp().toolbar().buttons()[0].tap();
  } else {
    target.frontMostApp().navigationBar().leftButton().tap();
  }
  target.delay(1);
}

function csgo() {
  window.tableViews()[0].cells()["Counter-Strike: Global Offensive"].tap();
  target.delay(1);
  var name = languageIs("ru") ? 'Расплата' : 'Payback';
  window.tableViews()[0].cells().firstWithPredicate("name CONTAINS '" + name + "'").tap();
  target.delay(3);

  captureLocalizedScreenshot("csgo");

  target.frontMostApp().navigationBar().leftButton().tap();
  target.delay(1);
  if (!isTablet()) {
    target.frontMostApp().navigationBar().leftButton().tap();
    target.delay(1);
  }
}

function tf2() {
  window.tableViews()[0].cells()["Team Fortress 2"].tap();
  target.delay(10);

  if (languageIs("ru")) {
    window.tableViews()[0].cells()["Огнемет"].scrollToVisible();
    target.delay(1);
    window.tableViews()[0].cells()["Огнемет"].tap();
  } else {
    window.tableViews()[0].cells()[0].tap();
  }

  target.delay(3);

  captureLocalizedScreenshot("tf2");

  target.frontMostApp().navigationBar().leftButton().tap();
  target.delay(1);
  if (!isTablet()) {
    target.frontMostApp().navigationBar().leftButton().tap();
    target.delay(1);
  }
}

function dota2() {
  window.tableViews()[0].cells()["Dota 2"].tap();
  target.delay(3);
  window.tableViews()[0].searchBars()[0].setValue("cor");
  target.delay(10);

  window.tableViews()[0].cells()[12].scrollToVisible();
  target.delay(1);
  window.tableViews()[0].searchBars()[0].scrollToVisible();
  target.delay(1);

  if (isTablet()) {
    window.tableViews()[0].cells().firstWithPredicate("name CONTAINS 'Encore'").tap();
    target.delay(5);
  }

  captureLocalizedScreenshot("dota2");

  target.frontMostApp().navigationBar().leftButton().tap();
  target.delay(1);
  if (isTablet()) {
    target.frontMostApp().navigationBar().leftButton().tap();
    target.delay(1);
  }
}

function getLanguage() {
  var result = target.host().performTaskWithPathArgumentsTimeout("/usr/bin/printenv", ["SNAPSHOT_LANGUAGE"], 5);
  return result.stdout.substring(0, result.stdout.length - 1);
}

function isTablet() {
  return !(UIATarget.localTarget().model().match(/iPhone/))
}

function languageIs(language) {
  return getLanguage() == language;
}

function captureLocalizedScreenshot(name) {
  var target = UIATarget.localTarget();
  var model = target.model();
  var rect = target.rect();
  var deviceOrientation = target.deviceOrientation();

  var theSize = (rect.size.width > rect.size.height) ? rect.size.width.toFixed() : rect.size.height.toFixed();

  if (model.match(/iPhone/)) {
    if (theSize > 667) {
      model = "iPhone6Plus";
    } else if (theSize == 667) {
      model = "iPhone6";
    } else if (theSize == 568) {
      model = "iPhone5";
    } else {
      model = "iPhone4";
    }
  } else {
    model = "iPad";
  }

  var parts = [getLanguage(), model, name];
  target.captureScreenWithName(parts.join("-"));
}
