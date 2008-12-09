#Builds for float version by default. If you want to use
#the doubles version, run qmake "CONFIG += build64"
#CONFIG += build64

DEFINES += QUTE_USE_CSOUNDPERFORMANCETHREAD
CONFIG += qute_cpp

build64 {
    message(Building for doubles \(64-bit\) csound)
    DEFINES += USE_DOUBLE
}
else {
    message(Building for float \(32-bit\) csound.)
    message(For doubles use qmake \"CONFIG += build64\")
}

SOURCES += qutecsound.cpp \
           main.cpp \
 dockhelp.cpp \
 opentryparser.cpp \
 options.cpp \
 highlighter.cpp \
 configdialog.cpp \
 configlists.cpp \
 console.cpp \
 documentpage.cpp \
 utilitiesdialog.cpp \
 widgetpanel.cpp \
 qutewidget.cpp \
 quteslider.cpp \
 findreplace.cpp \
 qutetext.cpp \
 qutebutton.cpp \
 qutedummy.cpp \
 quteknob.cpp \
 qutecombobox.cpp \
 qutecheckbox.cpp \
 quteconsole.cpp \
 qutemeter.cpp \
 qutegraph.cpp \
 framewidget.cpp
HEADERS += qutecsound.h \
 dockhelp.h \
 opentryparser.h \
 options.h \
 highlighter.h \
 types.h \
 configdialog.h \
 configlists.h \
 console.h \
 documentpage.h \
 utilitiesdialog.h \
 widgetpanel.h \
 qutewidget.h \
 quteslider.h \
 findreplace.h \
 qutetext.h \
 qutebutton.h \
 qutedummy.h \
 quteknob.h \
 qutecombobox.h \
 qutecheckbox.h \
 quteconsole.h \
 qutemeter.h \
 qutegraph.h \
 framewidget.h
TEMPLATE = app
CONFIG += warn_on \
	  thread \
          qt \
 release
TARGET = ../bin/qutecsound
RESOURCES = application.qrc

QT += xml

DISTFILES += default.csd \
 opcodes.xml \
 qutecsound.rc \
 test.csd

FORMS += configdialog.ui \
  utilitiesdialog.ui \
 findreplace.ui

win32 {
    DEFINES +=WIN32
    INCLUDEPATH += "C:\Archivos de programa\Csound\include"
    HEADERS += "C:\Archivos de programa\Csound\include\csound.h"
    qute_cpp {
        HEADERS += "C:\Archivos de programa\Csound\include\csound.hpp"
        HEADERS += "C:\Archivos de programa\Csound\include\csPerfThread.hpp"
        LIBS += "C:\Archivos de programa\Csound\bin\csnd.dll"
    }
    build64 {
        LIBS += "C:\Archivos de programa\Csound\bin\Csound64.dll.5.1"
    }
    else {
        LIBS += "C:\Archivos de programa\Csound\bin\Csound32.dll.5.1"
    }
    RC_FILE = qutecsound.rc
}

linux-g++ {
    DEFINES +=LINUX    
    INCLUDEPATH += /usr/local/include/csound/ /usr/include/csound/
    qute_cpp {
        LIBS += -lcsnd
    }
    build64 {
        LIBS += -lcsound64
    }
    else {
        LIBS += -lcsound
    }
}

macx {
    build64 {
        MAC_LIB = CsoundLib64
    }
    else {
        MAC_LIB = CsoundLib
    }
    message(Building using $${MAC_LIB})
    DEFINES +=MACOSX
    HEADERS += /Library/Frameworks/CsoundLib.framework/Versions/Current/Headers/csound.h
    qute_cpp {
        HEADERS += /Library/Frameworks/CsoundLib.framework/Versions/Current/Headers/csound.hpp
        HEADERS += /Library/Frameworks/CsoundLib.framework/Versions/Current/Headers/csPerfThread.hpp
        LIBS += /Library/Frameworks/CsoundLib.framework/Versions/Current/lib_csnd.dylib
    }
    LIBS += -framework QtXml
    LIBS += -framework QtGui
    LIBS += -framework QtCore
    LIBS += -framework $${MAC_LIB}
    LIBS += -L/Library/Frameworks/$${MAC_LIB}.framework/Versions/Current
    QMAKE_INFO_PLIST = MyInfo.plist
    ICON = ../images/qtcs.icns
}


#QMAKE_CXXFLAGS_DEBUG += -DDEBUG

CONFIG -= stl \
 debug

