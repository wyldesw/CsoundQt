/***************************************************************************
 *   Copyright (C) 2008 by Andres Cabrera   *
 *   mantaraya36@gmail.com   *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 3 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.             *
 ***************************************************************************/
#ifndef DOCKHELP_H
#define DOCKHELP_H

#include <QDockWidget>
#include "types.h"

class QTextBrowser;

class DockHelp : public QDockWidget
{
  Q_OBJECT
  public:
    DockHelp(QWidget *parent);

    ~DockHelp();

    void loadFile(QString fileName);
    bool externalBrowser;
    QString docDir;

  private:
    QTextBrowser *text;
    virtual void closeEvent(QCloseEvent * event);

  signals:
    void Close(bool visible);

  public slots:
    void showGen();
    void showOverview();
	void browseBack();
	void browseForward();
};

#endif
