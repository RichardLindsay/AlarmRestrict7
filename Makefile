GO_EASY_ON_ME = 1
export THEOS_DEVICE_IP=192.168.1.10
export TARGET = iphone::7.0
export ARCHS = armv7 arm64
include theos/makefiles/common.mk

TWEAK_NAME = alarmrestrict7
alarmrestrict7_FILES = Tweak.xm
alarmrestrict7_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	ssh root@192.168.1.10 "> /var/log/syslog" # Clears syslog!
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += alarmrestrict7
include $(THEOS_MAKE_PATH)/aggregate.mk
