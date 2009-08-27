/*
    Copyright (C) 2008, 2009 Andres Cabrera
              (C) 2003 by John D. Ramsdell
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

#include "curve.h"

// Curve is a straightforward abstract data type for a curve

float *Curve::copy(size_t size, float *data)
{
  float *result = new float[size];
  for (size_t i = 0; i < size; i++)
    result[i] = data[i];
  return result;
}

float *Curve::copy(size_t size, double *data)
{
  float *result = new float[size];
  for (size_t i = 0; i < size; i++)
    result[i] = data[i];
  return result;
}

void Curve::destroy()
{
  delete [] m_data;
}

Curve::Curve(float *data, size_t size, const QString& caption,
             Polarity polarity, float max, float min, float absmax,
             float y_scale, bool dotted_divider)
  : m_caption(caption)
{
  m_data = copy(size, data);
  m_size = size;
  m_polarity = polarity;
  m_max = max;
  m_min = min;
  m_absmax = absmax;
  m_y_scale = y_scale;
  m_dotted_divider = dotted_divider;
}

Curve::Curve(double *data, size_t size, const QString& caption,
             Polarity polarity, double max, double min, double absmax,
             double y_scale, bool dotted_divider)
  : m_caption(caption)
{
  m_data = copy(size, data);
  m_size = size;
  m_polarity = polarity;
  m_max = max;
  m_min = min;
  m_absmax = absmax;
  m_y_scale = y_scale;
  m_dotted_divider = dotted_divider;
}

Curve::Curve(const Curve& curve)
  : m_caption(curve.m_caption)
{
  m_data = copy(curve.m_size, curve.m_data);
  m_size = curve.m_size;
  m_polarity = curve.m_polarity;
  m_max = curve.m_max;
  m_min = curve.m_min;
  m_absmax = curve.m_absmax;
  m_y_scale = curve.m_y_scale;
  m_dotted_divider = curve.m_dotted_divider;
}

Curve& Curve::operator=(const Curve& curve)
{
  if (this != &curve) {
    destroy();
    m_data = copy(curve.m_size, curve.m_data);
    m_size = curve.m_size;
    m_caption = curve.m_caption;
    m_polarity = curve.m_polarity;
    m_max = curve.m_max;
    m_min = curve.m_min;
    m_absmax = curve.m_absmax;
    m_y_scale = curve.m_y_scale;
    m_dotted_divider = curve.m_dotted_divider;
  }
  return *this;
}

Curve::~Curve()
{
  destroy();
}

size_t Curve::get_size() const
{
  return m_size;
}

uintptr_t Curve::get_id() const
{
  return m_id;
}

float *Curve::get_data() const
{
  return m_data;
}

QString Curve::get_caption() const
{
  return m_caption;
}

Polarity Curve::get_polarity() const
{
  return m_polarity;
}

float Curve::get_max() const
{
  return m_max;
}

float Curve::get_min() const
{
  return m_min;
}

float Curve::get_absmax() const
{
  return m_absmax;
}

float Curve::get_y_scale() const
{
  return m_y_scale;
}

void Curve::set_id(uintptr_t id)
{
  m_id = id;
}

void Curve::set_data(MYFLT * data)
{
  m_data = (float *)data;
}

void Curve::set_size(size_t size)
{
  m_size = size;
}

void Curve::set_caption(QString caption)
{
  m_caption = caption;
}

void Curve::set_polarity(Polarity polarity)
{
  m_polarity = polarity;
}

void Curve::set_max(float max)
{
  m_max = max;
}
void Curve::set_min(float min)
{
  m_min = min;
}

void Curve::set_absmax(float absmax)
{
  m_absmax = absmax;
}

void Curve::set_y_scale(float y_scale)
{
  m_y_scale = y_scale;
}

bool Curve::is_divider_dotted() const
{
  return m_dotted_divider;
}

bool Curve::has_same_caption(Curve *curve) const
{
  return curve && m_caption == curve->m_caption;
}

