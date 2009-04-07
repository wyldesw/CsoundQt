/*
    Copyright (C) 2008, 2009 Andres Cabrera
    mantaraya36@gmail.com

    This file is part of QuteCsound.

    QuteCsound is free software; you can redistribute it
    and/or modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    QuteCsound is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with Csound; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
    02111-1307 USA
*/

#include "quteslider.h"

QuteSlider::QuteSlider(QWidget *parent) : QuteWidget(parent)
{
  m_widget = new QSlider(this);
  m_widget->setContextMenuPolicy(Qt::NoContextMenu);
  m_max = 1.0;
  m_min = 0.0;
  if (width() > height())
    static_cast<QSlider *>(m_widget)->setOrientation(Qt::Horizontal);
  else
    static_cast<QSlider *>(m_widget)->setOrientation(Qt::Vertical);

  connect(static_cast<QSlider *>(m_widget), SIGNAL(valueChanged(int)), this, SLOT(valueChanged(int)));
}

QuteSlider::~QuteSlider()
{
}

double QuteSlider::getValue()
{
//   QSlider *slider = static_cast<QSlider *>(m_widget);
//   double normalized = (double) slider->value() / (double) m_len;
//   m_value = m_min + (normalized * (m_max-m_min));
  return m_value;
}

void QuteSlider::valueChanged(int value)
{
  double normalized = (double) value / (double) m_len;
  m_value = m_min + (normalized * (m_max-m_min));
  QuteWidget::valueChanged(m_value);
}

void QuteSlider::setRange(double min, double max)
{
  if (max < min) {
    double temp = max;
    max = min;
    min = temp;
  }
  m_min = min;
  m_max = max;
  if (m_value > m_max)
    m_value = m_max;
  else if (m_value > m_min)
    m_value = m_min;
}

void QuteSlider::setValue(double value)
{
  if (value > m_max)
    m_value = m_max;
  else if (value < m_min)
    m_value = m_min;
  else
    m_value = value;
  int val = (int) (m_len * (m_value - m_min)/(m_max-m_min));
#ifdef  USE_WIDGET_MUTEX
  mutex.lock();
#endif
  static_cast<QSlider *>(m_widget)->setValue(val);
#ifdef  USE_WIDGET_MUTEX
  mutex.unlock();
#endif
}

void QuteSlider::setWidgetGeometry(int x, int y, int w, int h)
{
  QuteWidget::setWidgetGeometry(x,y,w,h);
  if (width() > height()) {
    static_cast<QSlider *>(m_widget)->setOrientation(Qt::Horizontal);
    static_cast<QSlider *>(m_widget)->setMaximum(w);
    m_len = w;
  }
  else {
    static_cast<QSlider *>(m_widget)->setOrientation(Qt::Vertical);
    static_cast<QSlider *>(m_widget)->setMaximum(h);
    m_len = h;
  }
}

void QuteSlider::setWidgetLine(QString line)
{
  m_line = line;
}

QString QuteSlider::getWidgetLine()
{
  QString line = "ioSlider {" + QString::number(x()) + ", " + QString::number(y()) + "} ";
  line += "{"+ QString::number(width()) +", "+ QString::number(height()) +"} ";
  line += QString::number(m_min, 'f', 6) + " " + QString::number(m_max, 'f', 6) + " ";
  line += QString::number(m_value, 'f', 6) + " " + m_name;
//   qDebug("QuteSlider::getWidgetLine() %s", line.toStdString().c_str());
  return line;
}

QString QuteSlider::getCsladspaLine()
{
  QString line = "ControlPort=" + m_name + "|" + m_name + "\n";
  line += "Range=" + QString::number(m_min, 'f', 6) + "|" + QString::number(m_max, 'f', 6);
  return line;
}

QString QuteSlider::getCabbageLine()
{
  QString line = "";
  return line;
}

void QuteSlider::createPropertiesDialog()
{
  QuteWidget::createPropertiesDialog();
  dialog->setWindowTitle("Slider");
  QLabel *label = new QLabel(dialog);
  label->setText("Min =");
  layout->addWidget(label, 2, 0, Qt::AlignRight|Qt::AlignVCenter);
  minSpinBox = new QDoubleSpinBox(dialog);
  minSpinBox->setDecimals(6);
  minSpinBox->setRange(-99999.0, 99999.0);
  minSpinBox->setValue(m_min);
  layout->addWidget(minSpinBox, 2,1, Qt::AlignLeft|Qt::AlignVCenter);
  label = new QLabel(dialog);
  label->setText("Max =");
  layout->addWidget(label, 2, 2, Qt::AlignRight|Qt::AlignVCenter);
  maxSpinBox = new QDoubleSpinBox(dialog);
  maxSpinBox->setDecimals(6);
  maxSpinBox->setRange(-99999.0, 99999.0);
  maxSpinBox->setValue(m_max);
  layout->addWidget(maxSpinBox, 2,3, Qt::AlignLeft|Qt::AlignVCenter);
}

void QuteSlider::applyProperties()
{
  setRange(maxSpinBox->value(), minSpinBox->value());
  QuteWidget::applyProperties();  //Must be last to make sure the widgetsChanged signal is last
}

