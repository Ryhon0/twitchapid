// Written in the D programming language

/**
 * $(RED Deprecated: This module is considered out-dated and not up to Phobos'
 *       current standards.)
 *
 * Source:    $(PHOBOSSRC std/_stream.d)
 * Macros:
 *      WIKI = Phobos/StdStream
 */

/*
 * Copyright (c) 2001-2005
 * Pavel "EvilOne" Minayev
 *  with buffering and endian support added by Ben Hinkle
 *  with buffered readLine performance improvements by Dave Fladebo
 *  with opApply inspired by (and mostly copied from) Regan Heath
 *  with bug fixes and MemoryStream/SliceStream enhancements by Derick Eddington
 *
 * Permission to use, copy, modify, distribute and sell this software
 * and its documentation for any purpose is hereby granted without fee,
 * provided that the above copyright notice appear in all copies and
 * that both that copyright notice and this permission notice appear
 * in supporting documentation.  Author makes no representations about
 * the suitability of this software for any purpose. It is provided
 * "as is" without express or implied warranty.
 */
module ircbod.stream;

import std.internal.cstring;

/* Class structure:
 *  InputStream       interface for reading
 *  OutputStream      interface for writing
 *  Stream            abstract base of stream implementations
 *    File            an OS file stream
 *    FilterStream    a base-class for wrappers around another stream
 *      BufferedStream  a buffered stream wrapping another stream
 *        BufferedFile  a buffered File
 *      EndianStream    a wrapper stream for swapping byte order and BOMs
 *      SliceStream     a portion of another stream
 *    MemoryStream    a stream entirely stored in main memory
 *    TArrayStream    a stream wrapping an array-like buffer
 */

/// A base class for stream exceptions.
class StreamException: Exception {
  /// Construct a StreamException with given error message.
  this(string msg) { super(msg); }
}

/// Thrown when unable to read data from Stream.
class ReadException: StreamException {
  /// Construct a ReadException with given error message.
  this(string msg) { super(msg); }
}

/// Thrown when unable to write data to Stream.
class WriteException: StreamException {
  /// Construct a WriteException with given error message.
  this(string msg) { super(msg); }
}

/// Thrown when unable to move Stream pointer.
class SeekException: StreamException {
  /// Construct a SeekException with given error message.
  this(string msg) { super(msg); }
}

// seek whence...
enum SeekPos {
  Set,
  Current,
  End
}

private {
  import std.conv;
  import std.algorithm;
  import std.ascii;
  //import std.format;
  import std.system;    // for Endian enumeration
  import std.utf;
  import core.bitop; // for bswap
  import core.vararg;
  static import std.file;
}

/// InputStream is the interface for readable streams.

interface InputStream {

  /***
   * Read exactly size bytes into the buffer.
   *
   * Throws a ReadException if it is not correct.
   */
  void readExact(void* buffer, size_t size);

  /***
   * Read a block of data big enough to fill the given array buffer.
   *
   * Returns: the actual number of bytes read. Unfilled bytes are not modified.
   */
  size_t read(ubyte[] buffer);

  /***
   * Read a basic type or counted string.
   *
   * Throw a ReadException if it could not be read.
   * Outside of byte, ubyte, and char, the format is
   * implementation-specific and should not be used except as opposite actions
   * to write.
   */
  void read(out byte x);
  void read(out ubyte x);       /// ditto
  void read(out short x);       /// ditto
  void read(out ushort x);      /// ditto
  void read(out int x);         /// ditto
  void read(out uint x);        /// ditto
  void read(out long x);        /// ditto
  void read(out ulong x);       /// ditto
  void read(out float x);       /// ditto
  void read(out double x);      /// ditto
  void read(out real x);        /// ditto
  void read(out ifloat x);      /// ditto
  void read(out idouble x);     /// ditto
  void read(out ireal x);       /// ditto
  void read(out cfloat x);      /// ditto
  void read(out cdouble x);     /// ditto
  void read(out creal x);       /// ditto
  void read(out char x);        /// ditto
  void read(out wchar x);       /// ditto
  void read(out dchar x);       /// ditto

  // reads a string, written earlier by write()
  void read(out char[] s);      /// ditto

  // reads a Unicode string, written earlier by write()
  void read(out wchar[] s);     /// ditto

  /***
   * Read a line that is terminated with some combination of carriage return and
   * line feed or end-of-file.
   *
   * The terminators are not included. The wchar version
   * is identical. The optional buffer parameter is filled (reallocating
   * it if necessary) and a slice of the result is returned.
   */
  char[] readLine();
  char[] readLine(char[] result);       /// ditto
  wchar[] readLineW();                  /// ditto
  wchar[] readLineW(wchar[] result);    /// ditto

  /***
   * Overload foreach statements to read the stream line by line and call the
   * supplied delegate with each line or with each line with line number.
   *
   * The string passed in line may be reused between calls to the delegate.
   * Line numbering starts at 1.
   * Breaking out of the foreach will leave the stream
   * position at the beginning of the next line to be read.
   * For example, to echo a file line-by-line with line numbers run:
   * ------------------------------------
   * Stream file = new BufferedFile("sample.txt");
   * foreach(ulong n, char[] line; file)
   * {
   *     writefln("line %d: %s", n, line);
   * }
   * file.close();
   * ------------------------------------
   */

  // iterate through the stream line-by-line
  int opApply(scope int delegate(ref char[] line) dg);
  int opApply(scope int delegate(ref ulong n, ref char[] line) dg);  /// ditto
  int opApply(scope int delegate(ref wchar[] line) dg);            /// ditto
  int opApply(scope int delegate(ref ulong n, ref wchar[] line) dg); /// ditto

  /// Read a string of the given length,
  /// throwing ReadException if there was a problem.
  char[] readString(size_t length);

  /***
   * Read a string of the given length, throwing ReadException if there was a
   * problem.
   *
   * The file format is implementation-specific and should not be used
   * except as opposite actions to <b>write</b>.
   */

  wchar[] readStringW(size_t length);


  /***
   * Read and return the next character in the stream.
   *
   * This is the only method that will handle ungetc properly.
   * getcw's format is implementation-specific.
   * If EOF is reached then getc returns char.init and getcw returns wchar.init.
   */

  char getc();
  wchar getcw(); /// ditto

  /***
   * Push a character back onto the stream.
   *
   * They will be returned in first-in last-out order from getc/getcw.
   * Only has effect on further calls to getc() and getcw().
   */
  char ungetc(char c);
  wchar ungetcw(wchar c); /// ditto

  /***
   * Scan a string from the input using a similar form to C's scanf
   * and <a href="std_format.html">std.format</a>.
   *
   * An argument of type string is interpreted as a format string.
   * All other arguments must be pointer types.
   * If a format string is not present a default will be supplied computed from
   * the base type of the pointer type. An argument of type string* is filled
   * (possibly with appending characters) and a slice of the result is assigned
   * back into the argument. For example the following readf statements
   * are equivalent:
   * --------------------------
   * int x;
   * double y;
   * string s;
   * file.readf(&x, " hello ", &y, &s);
   * file.readf("%d hello %f %s", &x, &y, &s);
   * file.readf("%d hello %f", &x, &y, "%s", &s);
   * --------------------------
   */
  int vreadf(TypeInfo[] arguments, va_list args);
  int readf(...); /// ditto

  /// Retrieve the number of bytes available for immediate reading.
  @property size_t available();

  /***
   * Return whether the current file position is the same as the end of the
   * file.
   *
   * This does not require actually reading past the end, as with stdio. For
   * non-seekable streams this might only return true after attempting to read
   * past the end.
   */

  @property bool eof();

  @property bool isOpen();        /// Return true if the stream is currently open.
}

/// Interface for writable streams.
interface OutputStream {

  /***
   * Write exactly size bytes from buffer, or throw a WriteException if that
   * could not be done.
   */
  void writeExact(const void* buffer, size_t size);

  /***
   * Write as much of the buffer as possible,
   * returning the number of bytes written.
   */
  size_t write(const(ubyte)[] buffer);

  /***
   * Write a basic type.
   *
   * Outside of byte, ubyte, and char, the format is implementation-specific
   * and should only be used in conjunction with read.
   * Throw WriteException on error.
   */
  void write(byte x);
  void write(ubyte x);          /// ditto
  void write(short x);          /// ditto
  void write(ushort x);         /// ditto
  void write(int x);            /// ditto
  void write(uint x);           /// ditto
  void write(long x);           /// ditto
  void write(ulong x);          /// ditto
  void write(float x);          /// ditto
  void write(double x);         /// ditto
  void write(real x);           /// ditto
  void write(ifloat x);         /// ditto
  void write(idouble x);        /// ditto
  void write(ireal x);          /// ditto
  void write(cfloat x);         /// ditto
  void write(cdouble x);        /// ditto
  void write(creal x);          /// ditto
  void write(char x);           /// ditto
  void write(wchar x);          /// ditto
  void write(dchar x);          /// ditto

  /***
   * Writes a string, together with its length.
   *
   * The format is implementation-specific
   * and should only be used in conjunction with read.
   * Throw WriteException on error.
   */
    void write(const(char)[] s);
    void write(const(wchar)[] s); /// ditto

  /***
   * Write a line of text,
   * appending the line with an operating-system-specific line ending.
   *
   * Throws WriteException on error.
   */
  void writeLine(const(char)[] s);

  /***
   * Write a line of text,
   * appending the line with an operating-system-specific line ending.
   *
   * The format is implementation-specific.
   * Throws WriteException on error.
   */
    void writeLineW(const(wchar)[] s);

  /***
   * Write a string of text.
   *
   * Throws WriteException if it could not be fully written.
   */
    void writeString(const(char)[] s);

  /***
   * Write a string of text.
   *
   * The format is implementation-specific.
   * Throws WriteException if it could not be fully written.
   */
  void writeStringW(const(wchar)[] s);

  /***
   * Print a formatted string into the stream using printf-style syntax,
   * returning the number of bytes written.
   */
  size_t vprintf(const(char)[] format, va_list args);
  size_t printf(const(char)[] format, ...);    /// ditto

  void flush(); /// Flush pending output if appropriate.
  void close(); /// Close the stream, flushing output if appropriate.
  @property bool isOpen(); /// Return true if the stream is currently open.
}


/***
 * Stream is the base abstract class from which the other stream classes derive.
 *
 * Stream's byte order is the format native to the computer.
 *
 * Reading:
 * These methods require that the readable flag be set.
 * Problems with reading result in a ReadException being thrown.
 * Stream implements the InputStream interface in addition to the
 * readBlock method.
 *
 * Writing:
 * These methods require that the writeable flag be set. Problems with writing
 * result in a WriteException being thrown. Stream implements the OutputStream
 * interface in addition to the following methods:
 * writeBlock
 * copyFrom
 * copyFrom
 *
 * Seeking:
 * These methods require that the seekable flag be set.
 * Problems with seeking result in a SeekException being thrown.
 * seek, seekSet, seekCur, seekEnd, position, size, toString, toHash
 */

// not really abstract, but its instances will do nothing useful
class Stream : InputStream, OutputStream {
  private import std.string, std.digest.crc, core.stdc.stdlib, core.stdc.stdio;

  // stream abilities
  bool readable = false;        /// Indicates whether this stream can be read from.
  bool writeable = false;       /// Indicates whether this stream can be written to.
  bool seekable = false;        /// Indicates whether this stream can be seeked within.
  protected bool isopen = true; /// Indicates whether this stream is open.

  protected bool readEOF = false; /** Indicates whether this stream is at eof
                                   * after the last read attempt.
                                   */

  protected bool prevCr = false; /** For a non-seekable stream indicates that
                                  * the last readLine or readLineW ended on a
                                  * '\r' character.
                                  */

  this() {}

  /***
   * Read up to size bytes into the buffer and return the number of bytes
   * actually read. A return value of 0 indicates end-of-file.
   */
  abstract size_t readBlock(void* buffer, size_t size);

  // reads block of data of specified size,
  // throws ReadException on error
  void readExact(void* buffer, size_t size) {
    for(;;) {
      if (!size) return;
      size_t readsize = readBlock(buffer, size); // return 0 on eof
      if (readsize == 0) break;
      buffer += readsize;
      size -= readsize;
    }
    if (size != 0)
      throw new ReadException("not enough data in stream");
  }

  // reads block of data big enough to fill the given
  // array, returns actual number of bytes read
  size_t read(ubyte[] buffer) {
    return readBlock(buffer.ptr, buffer.length);
  }

  // read a single value of desired type,
  // throw ReadException on error
  void read(out byte x) { readExact(&x, x.sizeof); }
  void read(out ubyte x) { readExact(&x, x.sizeof); }
  void read(out short x) { readExact(&x, x.sizeof); }
  void read(out ushort x) { readExact(&x, x.sizeof); }
  void read(out int x) { readExact(&x, x.sizeof); }
  void read(out uint x) { readExact(&x, x.sizeof); }
  void read(out long x) { readExact(&x, x.sizeof); }
  void read(out ulong x) { readExact(&x, x.sizeof); }
  void read(out float x) { readExact(&x, x.sizeof); }
  void read(out double x) { readExact(&x, x.sizeof); }
  void read(out real x) { readExact(&x, x.sizeof); }
  void read(out ifloat x) { readExact(&x, x.sizeof); }
  void read(out idouble x) { readExact(&x, x.sizeof); }
  void read(out ireal x) { readExact(&x, x.sizeof); }
  void read(out cfloat x) { readExact(&x, x.sizeof); }
  void read(out cdouble x) { readExact(&x, x.sizeof); }
  void read(out creal x) { readExact(&x, x.sizeof); }
  void read(out char x) { readExact(&x, x.sizeof); }
  void read(out wchar x) { readExact(&x, x.sizeof); }
  void read(out dchar x) { readExact(&x, x.sizeof); }

  // reads a string, written earlier by write()
  void read(out char[] s) {
    size_t len;
    read(len);
    s = readString(len);
  }

  // reads a Unicode string, written earlier by write()
  void read(out wchar[] s) {
    size_t len;
    read(len);
    s = readStringW(len);
  }

  // reads a line, terminated by either CR, LF, CR/LF, or EOF
  char[] readLine() {
    return readLine(null);
  }

  // reads a line, terminated by either CR, LF, CR/LF, or EOF
  // reusing the memory in buffer if result will fit and otherwise
  // allocates a new string
  char[] readLine(char[] result) {
    size_t strlen;
    char ch = getc();
    while (readable) {
      switch (ch) {
      case '\r':
        if (seekable) {
          ch = getc();
          if (ch != '\n')
            ungetc(ch);
        } else {
          prevCr = true;
        }
        goto case;
      case '\n':
      case char.init:
        result.length = strlen;
        return result;
      default:
        if (strlen < result.length) {
          result[strlen] = ch;
        } else {
          result ~= ch;
        }
        strlen++;
      }
      ch = getc();
    }
    result.length = strlen;
    return result;
  }

  // reads a Unicode line, terminated by either CR, LF, CR/LF,
  // or EOF; pretty much the same as the above, working with
  // wchars rather than chars
  wchar[] readLineW() {
    return readLineW(null);
  }

  // reads a Unicode line, terminated by either CR, LF, CR/LF,
  // or EOF;
  // fills supplied buffer if line fits and otherwise allocates a new string.
  wchar[] readLineW(wchar[] result) {
    size_t strlen;
    wchar c = getcw();
    while (readable) {
      switch (c) {
      case '\r':
        if (seekable) {
          c = getcw();
          if (c != '\n')
            ungetcw(c);
        } else {
          prevCr = true;
        }
        goto case;
      case '\n':
      case wchar.init:
        result.length = strlen;
        return result;

      default:
        if (strlen < result.length) {
          result[strlen] = c;
        } else {
          result ~= c;
        }
        strlen++;
      }
      c = getcw();
    }
    result.length = strlen;
    return result;
  }

  // iterate through the stream line-by-line - due to Regan Heath
  int opApply(scope int delegate(ref char[] line) dg) {
    int res;
    char[128] buf;
    while (!eof) {
      char[] line = readLine(buf);
      res = dg(line);
      if (res) break;
    }
    return res;
  }

  // iterate through the stream line-by-line with line count and string
  int opApply(scope int delegate(ref ulong n, ref char[] line) dg) {
    int res;
    ulong n = 1;
    char[128] buf;
    while (!eof) {
      auto line = readLine(buf);
      res = dg(n,line);
      if (res) break;
      n++;
    }
    return res;
  }

  // iterate through the stream line-by-line with wchar[]
  int opApply(scope int delegate(ref wchar[] line) dg) {
    int res;
    wchar[128] buf;
    while (!eof) {
      auto line = readLineW(buf);
      res = dg(line);
      if (res) break;
    }
    return res;
  }

  // iterate through the stream line-by-line with line count and wchar[]
  int opApply(scope int delegate(ref ulong n, ref wchar[] line) dg) {
    int res;
    ulong n = 1;
    wchar[128] buf;
    while (!eof) {
      auto line = readLineW(buf);
      res = dg(n,line);
      if (res) break;
      n++;
    }
    return res;
  }

  // reads a string of given length, throws
  // ReadException on error
  char[] readString(size_t length) {
    char[] result = new char[length];
    readExact(result.ptr, length);
    return result;
  }

  // reads a Unicode string of given length, throws
  // ReadException on error
  wchar[] readStringW(size_t length) {
    auto result = new wchar[length];
    readExact(result.ptr, result.length * wchar.sizeof);
    return result;
  }

  // unget buffer
  private wchar[] unget;
  final bool ungetAvailable() { return unget.length > 1; }

  // reads and returns next character from the stream,
  // handles characters pushed back by ungetc()
  // returns char.init on eof.
  char getc() {
    char c;
    if (prevCr) {
      prevCr = false;
      c = getc();
      if (c != '\n')
        return c;
    }
    if (unget.length > 1) {
      c = cast(char)unget[unget.length - 1];
      unget.length = unget.length - 1;
    } else {
      readBlock(&c,1);
    }
    return c;
  }

  // reads and returns next Unicode character from the
  // stream, handles characters pushed back by ungetc()
  // returns wchar.init on eof.
  wchar getcw() {
    wchar c;
    if (prevCr) {
      prevCr = false;
      c = getcw();
      if (c != '\n')
        return c;
    }
    if (unget.length > 1) {
      c = unget[unget.length - 1];
      unget.length = unget.length - 1;
    } else {
      void* buf = &c;
      size_t n = readBlock(buf,2);
      if (n == 1 && readBlock(buf+1,1) == 0)
          throw new ReadException("not enough data in stream");
    }
    return c;
  }

  // pushes back character c into the stream; only has
  // effect on further calls to getc() and getcw()
  char ungetc(char c) {
    if (c == c.init) return c;
    // first byte is a dummy so that we never set length to 0
    if (unget.length == 0)
      unget.length = 1;
    unget ~= c;
    return c;
  }

  // pushes back Unicode character c into the stream; only
  // has effect on further calls to getc() and getcw()
  wchar ungetcw(wchar c) {
    if (c == c.init) return c;
    // first byte is a dummy so that we never set length to 0
    if (unget.length == 0)
      unget.length = 1;
    unget ~= c;
    return c;
  }

  int vreadf(TypeInfo[] arguments, va_list args) {
    string fmt;
    int i, j, count;
    char c;
    bool firstCharacter = true;
    while ((j < arguments.length || i < fmt.length) && !eof) {
      if(firstCharacter) {
        c = getc();
        firstCharacter = false;
      }
      if (fmt.length == 0 || i == fmt.length) {
        i = 0;
        if (arguments[j] is typeid(string) || arguments[j] is typeid(char[])
            || arguments[j] is typeid(const(char)[])) {
          fmt = va_arg!(string)(args);
          j++;
          continue;
        } else if (arguments[j] is typeid(int*) ||
                   arguments[j] is typeid(byte*) ||
                   arguments[j] is typeid(short*) ||
                   arguments[j] is typeid(long*)) {
          fmt = "%d";
        } else if (arguments[j] is typeid(uint*) ||
                   arguments[j] is typeid(ubyte*) ||
                   arguments[j] is typeid(ushort*) ||
                   arguments[j] is typeid(ulong*)) {
          fmt = "%d";
        } else if (arguments[j] is typeid(float*) ||
                   arguments[j] is typeid(double*) ||
                   arguments[j] is typeid(real*)) {
          fmt = "%f";
        } else if (arguments[j] is typeid(char[]*) ||
                   arguments[j] is typeid(wchar[]*) ||
                   arguments[j] is typeid(dchar[]*)) {
          fmt = "%s";
        } else if (arguments[j] is typeid(char*)) {
          fmt = "%c";
        }
      }
      if (fmt[i] == '%') {      // a field
        i++;
        bool suppress;
        if (fmt[i] == '*') {    // suppress assignment
          suppress = true;
          i++;
        }
        // read field width
        int width;
        while (isDigit(fmt[i])) {
          width = width * 10 + (fmt[i] - '0');
          i++;
        }
        if (width == 0)
          width = -1;
        // skip any modifier if present
        if (fmt[i] == 'h' || fmt[i] == 'l' || fmt[i] == 'L')
          i++;
        // check the typechar and act accordingly
        switch (fmt[i]) {
        case 'd':       // decimal/hexadecimal/octal integer
        case 'D':
        case 'u':
        case 'U':
        case 'o':
        case 'O':
        case 'x':
        case 'X':
        case 'i':
        case 'I':
          {
            while (isWhite(c)) {
              c = getc();
              count++;
            }
            bool neg;
            if (c == '-') {
              neg = true;
              c = getc();
              count++;
            } else if (c == '+') {
              c = getc();
              count++;
            }
            char ifmt = cast(char)(fmt[i] | 0x20);
            if (ifmt == 'i')    { // undetermined base
              if (c == '0')     { // octal or hex
                c = getc();
                count++;
                if (c == 'x' || c == 'X')       { // hex
                  ifmt = 'x';
                  c = getc();
                  count++;
                } else {        // octal
                  ifmt = 'o';
                }
              }
              else      // decimal
                ifmt = 'd';
            }
            long n;
            switch (ifmt)
            {
                case 'd':       // decimal
                case 'u': {
                  while (isDigit(c) && width) {
                    n = n * 10 + (c - '0');
                    width--;
                    c = getc();
                    count++;
                  }
                } break;

                case 'o': {     // octal
                  while (isOctalDigit(c) && width) {
                    n = n * 8 + (c - '0');
                    width--;
                    c = getc();
                    count++;
                  }
                } break;

                case 'x': {     // hexadecimal
                  while (isHexDigit(c) && width) {
                    n *= 0x10;
                    if (isDigit(c))
                      n += c - '0';
                    else
                      n += 0xA + (c | 0x20) - 'a';
                    width--;
                    c = getc();
                    count++;
                  }
                } break;

                default:
                    assert(0);
            }
            if (neg)
              n = -n;
            if (arguments[j] is typeid(int*)) {
              int* p = va_arg!(int*)(args);
              *p = cast(int)n;
            } else if (arguments[j] is typeid(short*)) {
              short* p = va_arg!(short*)(args);
              *p = cast(short)n;
            } else if (arguments[j] is typeid(byte*)) {
              byte* p = va_arg!(byte*)(args);
              *p = cast(byte)n;
            } else if (arguments[j] is typeid(long*)) {
              long* p = va_arg!(long*)(args);
              *p = n;
            } else if (arguments[j] is typeid(uint*)) {
              uint* p = va_arg!(uint*)(args);
              *p = cast(uint)n;
            } else if (arguments[j] is typeid(ushort*)) {
              ushort* p = va_arg!(ushort*)(args);
              *p = cast(ushort)n;
            } else if (arguments[j] is typeid(ubyte*)) {
              ubyte* p = va_arg!(ubyte*)(args);
              *p = cast(ubyte)n;
            } else if (arguments[j] is typeid(ulong*)) {
              ulong* p = va_arg!(ulong*)(args);
              *p = cast(ulong)n;
            }
            j++;
            i++;
          } break;

        case 'f':       // float
        case 'F':
        case 'e':
        case 'E':
        case 'g':
        case 'G':
          {
            while (isWhite(c)) {
              c = getc();
              count++;
            }
            bool neg;
            if (c == '-') {
              neg = true;
              c = getc();
              count++;
            } else if (c == '+') {
              c = getc();
              count++;
            }
            real r = 0;
            while (isDigit(c) && width) {
              r = r * 10 + (c - '0');
              width--;
              c = getc();
              count++;
            }
            if (width && c == '.') {
              width--;
              c = getc();
              count++;
              double frac = 1;
              while (isDigit(c) && width) {
                r = r * 10 + (c - '0');
                frac *= 10;
                width--;
                c = getc();
                count++;
              }
              r /= frac;
            }
            if (width && (c == 'e' || c == 'E')) {
              width--;
              c = getc();
              count++;
              if (width) {
                bool expneg;
                if (c == '-') {
                  expneg = true;
                  width--;
                  c = getc();
                  count++;
                } else if (c == '+') {
                  width--;
                  c = getc();
                  count++;
                }
                real exp = 0;
                while (isDigit(c) && width) {
                  exp = exp * 10 + (c - '0');
                  width--;
                  c = getc();
                  count++;
                }
                if (expneg) {
                  while (exp--)
                    r /= 10;
                } else {
                  while (exp--)
                    r *= 10;
                }
              }
            }
            if(width && (c == 'n' || c == 'N')) {
              width--;
              c = getc();
              count++;
              if(width && (c == 'a' || c == 'A')) {
                width--;
                c = getc();
                count++;
                if(width && (c == 'n' || c == 'N')) {
                  width--;
                  c = getc();
                  count++;
                  r = real.nan;
                }
              }
            }
            if(width && (c == 'i' || c == 'I')) {
              width--;
              c = getc();
              count++;
              if(width && (c == 'n' || c == 'N')) {
                width--;
                c = getc();
                count++;
                if(width && (c == 'f' || c == 'F')) {
                  width--;
                  c = getc();
                  count++;
                  r = real.infinity;
                }
              }
            }
            if (neg)
              r = -r;
            if (arguments[j] is typeid(float*)) {
              float* p = va_arg!(float*)(args);
              *p = r;
            } else if (arguments[j] is typeid(double*)) {
              double* p = va_arg!(double*)(args);
              *p = r;
            } else if (arguments[j] is typeid(real*)) {
              real* p = va_arg!(real*)(args);
              *p = r;
            }
            j++;
            i++;
          } break;

        case 's': {     // string
          while (isWhite(c)) {
            c = getc();
            count++;
          }
          char[] s;
          char[]* p;
          size_t strlen;
          if (arguments[j] is typeid(char[]*)) {
            p = va_arg!(char[]*)(args);
            s = *p;
          }
          while (!isWhite(c) && c != char.init) {
            if (strlen < s.length) {
              s[strlen] = c;
            } else {
              s ~= c;
            }
            strlen++;
            c = getc();
            count++;
          }
          s = s[0 .. strlen];
          if (arguments[j] is typeid(char[]*)) {
            *p = s;
          } else if (arguments[j] is typeid(char*)) {
            s ~= 0;
            auto q = va_arg!(char*)(args);
            q[0 .. s.length] = s[];
          } else if (arguments[j] is typeid(wchar[]*)) {
            auto q = va_arg!(const(wchar)[]*)(args);
            *q = toUTF16(s);
          } else if (arguments[j] is typeid(dchar[]*)) {
            auto q = va_arg!(const(dchar)[]*)(args);
            *q = toUTF32(s);
          }
          j++;
          i++;
        } break;

        case 'c': {     // character(s)
          char* s = va_arg!(char*)(args);
          if (width < 0)
            width = 1;
          else
            while (isWhite(c)) {
            c = getc();
            count++;
          }
          while (width-- && !eof) {
            *(s++) = c;
            c = getc();
            count++;
          }
          j++;
          i++;
        } break;

        case 'n': {     // number of chars read so far
          int* p = va_arg!(int*)(args);
          *p = count;
          j++;
          i++;
        } break;

        default:        // read character as is
          goto nws;
        }
      } else if (isWhite(fmt[i])) {     // skip whitespace
        while (isWhite(c))
          c = getc();
        i++;
      } else {  // read character as is
      nws:
        if (fmt[i] != c)
          break;
        c = getc();
        i++;
      }
    }
    ungetc(c);
    return count;
  }

  int readf(...) {
    return vreadf(_arguments, _argptr);
  }

  // returns estimated number of bytes available for immediate reading
  @property size_t available() { return 0; }

  /***
   * Write up to size bytes from buffer in the stream, returning the actual
   * number of bytes that were written.
   */
  abstract size_t writeBlock(const void* buffer, size_t size);

  // writes block of data of specified size,
  // throws WriteException on error
  void writeExact(const void* buffer, size_t size) {
    const(void)* p = buffer;
    for(;;) {
      if (!size) return;
      size_t writesize = writeBlock(p, size);
      if (writesize == 0) break;
      p += writesize;
      size -= writesize;
    }
    if (size != 0)
      throw new WriteException("unable to write to stream");
  }

  // writes the given array of bytes, returns
  // actual number of bytes written
  size_t write(const(ubyte)[] buffer) {
    return writeBlock(buffer.ptr, buffer.length);
  }

  // write a single value of desired type,
  // throw WriteException on error
  void write(byte x) { writeExact(&x, x.sizeof); }
  void write(ubyte x) { writeExact(&x, x.sizeof); }
  void write(short x) { writeExact(&x, x.sizeof); }
  void write(ushort x) { writeExact(&x, x.sizeof); }
  void write(int x) { writeExact(&x, x.sizeof); }
  void write(uint x) { writeExact(&x, x.sizeof); }
  void write(long x) { writeExact(&x, x.sizeof); }
  void write(ulong x) { writeExact(&x, x.sizeof); }
  void write(float x) { writeExact(&x, x.sizeof); }
  void write(double x) { writeExact(&x, x.sizeof); }
  void write(real x) { writeExact(&x, x.sizeof); }
  void write(ifloat x) { writeExact(&x, x.sizeof); }
  void write(idouble x) { writeExact(&x, x.sizeof); }
  void write(ireal x) { writeExact(&x, x.sizeof); }
  void write(cfloat x) { writeExact(&x, x.sizeof); }
  void write(cdouble x) { writeExact(&x, x.sizeof); }
  void write(creal x) { writeExact(&x, x.sizeof); }
  void write(char x) { writeExact(&x, x.sizeof); }
  void write(wchar x) { writeExact(&x, x.sizeof); }
  void write(dchar x) { writeExact(&x, x.sizeof); }

  // writes a string, together with its length
  void write(const(char)[] s) {
    write(s.length);
    writeString(s);
  }

  // writes a Unicode string, together with its length
  void write(const(wchar)[] s) {
    write(s.length);
    writeStringW(s);
  }

  // writes a line, throws WriteException on error
  void writeLine(const(char)[] s) {
    writeString(s);
    version (Windows)
      writeString("\r\n");
    else version (Mac)
      writeString("\r");
    else
      writeString("\n");
  }

  // writes a Unicode line, throws WriteException on error
  void writeLineW(const(wchar)[] s) {
    writeStringW(s);
    version (Windows)
      writeStringW("\r\n");
    else version (Mac)
      writeStringW("\r");
    else
      writeStringW("\n");
  }

  // writes a string, throws WriteException on error
  void writeString(const(char)[] s) {
    writeExact(s.ptr, s.length);
  }

  // writes a Unicode string, throws WriteException on error
  void writeStringW(const(wchar)[] s) {
    writeExact(s.ptr, s.length * wchar.sizeof);
  }

  // writes data to stream using vprintf() syntax,
  // returns number of bytes written
  size_t vprintf(const(char)[] format, va_list args) {
    // shamelessly stolen from OutBuffer,
    // by Walter's permission
    char[1024] buffer;
    char* p = buffer.ptr;
    // Can't use `tempCString()` here as it will result in compilation error:
    // "cannot mix core.std.stdlib.alloca() and exception handling".
    auto f = toStringz(format);
    size_t psize = buffer.length;
    size_t count;
    while (true) {
      version (Windows) {
        count = vsnprintf(p, psize, f, args);
        if (count != -1)
          break;
        psize *= 2;
        p = cast(char*) alloca(psize);
      } else version (Posix) {
        count = vsnprintf(p, psize, f, args);
        if (count == -1)
          psize *= 2;
        else if (count >= psize)
          psize = count + 1;
        else
          break;
        p = cast(char*) alloca(psize);
      } else
          throw new Exception("unsupported platform");
    }
    writeString(p[0 .. count]);
    return count;
  }

  // writes data to stream using printf() syntax,
  // returns number of bytes written
  size_t printf(const(char)[] format, ...) {
    va_list ap;
    va_start(ap, format);
    auto result = vprintf(format, ap);
    va_end(ap);
    return result;
  }

  private void doFormatCallback(dchar c) {
    import std.conv : to;
    writeString(to!string(c));
  }

  /***
   * Copies all data from s into this stream.
   * This may throw ReadException or WriteException on failure.
   * This restores the file position of s so that it is unchanged.
   */
  void copyFrom(Stream s) {
    if (seekable) {
      const ulong pos = s.position;
      s.position = 0;
      copyFrom(s, s.size);
      s.position = pos;
    } else {
      ubyte[128] buf;
      while (!s.eof) {
        size_t m = s.readBlock(buf.ptr, buf.length);
        writeExact(buf.ptr, m);
      }
    }
  }

  /***
   * Copy a specified number of bytes from the given stream into this one.
   * This may throw ReadException or WriteException on failure.
   * Unlike the previous form, this doesn't restore the file position of s.
   */
  void copyFrom(Stream s, ulong count) {
    ubyte[128] buf;
    while (count > 0) {
      size_t n = cast(size_t)(count<buf.length ? count : buf.length);
      s.readExact(buf.ptr, n);
      writeExact(buf.ptr, n);
      count -= n;
    }
  }

  /***
   * Change the current position of the stream. whence is either SeekPos.Set, in
   which case the offset is an absolute index from the beginning of the stream,
   SeekPos.Current, in which case the offset is a delta from the current
   position, or SeekPos.End, in which case the offset is a delta from the end of
   the stream (negative or zero offsets only make sense in that case). This
   returns the new file position.
   */
  abstract ulong seek(long offset, SeekPos whence);

  /***
   * Aliases for their normal seek counterparts.
   */
  ulong seekSet(long offset) { return seek (offset, SeekPos.Set); }
  ulong seekCur(long offset) { return seek (offset, SeekPos.Current); } /// ditto
  ulong seekEnd(long offset) { return seek (offset, SeekPos.End); }     /// ditto

  /***
   * Sets file position. Equivalent to calling seek(pos, SeekPos.Set).
   */
  @property void position(ulong pos) { seek(cast(long)pos, SeekPos.Set); }

  /***
   * Returns current file position. Equivalent to seek(0, SeekPos.Current).
   */
  @property ulong position() { return seek(0, SeekPos.Current); }

  /***
   * Retrieve the size of the stream in bytes.
   * The stream must be seekable or a SeekException is thrown.
   */
  @property ulong size() {
    assertSeekable();
    ulong pos = position, result = seek(0, SeekPos.End);
    position = pos;
    return result;
  }

  // returns true if end of stream is reached, false otherwise
  @property bool eof() {
    // for unseekable streams we only know the end when we read it
    if (readEOF && !ungetAvailable())
      return true;
    else if (seekable)
      return position == size;
    else
      return false;
  }

  // returns true if the stream is open
  @property bool isOpen() { return isopen; }

  // flush the buffer if writeable
  void flush() {
    if (unget.length > 1)
      unget.length = 1; // keep at least 1 so that data ptr stays
  }

  // close the stream somehow; the default just flushes the buffer
  void close() {
    if (isopen)
      flush();
    readEOF = prevCr = isopen = readable = writeable = seekable = false;
  }

  /***
   * Read the entire stream and return it as a string.
   * If the stream is not seekable the contents from the current position to eof
   * is read and returned.
   */
  override string toString() {
    if (!readable)
      return super.toString();
    try
    {
        size_t pos;
        size_t rdlen;
        size_t blockSize;
        char[] result;
        if (seekable) {
          const ulong orig_pos = position;
          scope(exit) position = orig_pos;
          position = 0;
          blockSize = cast(size_t)size;
          result = new char[blockSize];
          while (blockSize > 0) {
            rdlen = readBlock(&result[pos], blockSize);
            pos += rdlen;
            blockSize -= rdlen;
          }
        } else {
          blockSize = 4096;
          result = new char[blockSize];
          while ((rdlen = readBlock(&result[pos], blockSize)) > 0) {
            pos += rdlen;
            blockSize += rdlen;
            result.length = result.length + blockSize;
          }
        }
        return cast(string) result[0 .. pos];
    }
    catch (Throwable)
    {
        return super.toString();
    }
  }

  /***
   * Get a hash of the stream by reading each byte and using it in a CRC-32
   * checksum.
   */
  override size_t toHash() @trusted {
    if (!readable || !seekable)
      return super.toHash();
    try
    {
        const ulong pos = position;
        scope(exit) position = pos;
        CRC32 crc;
        crc.start();
        position = 0;
        const ulong len = size;
        foreach (immutable i; 0..len)
        {
          ubyte c;
          read(c);
          crc.put(c);
        }

        union resUnion
        {
            size_t hash;
            ubyte[4] crcVal;
        }
        resUnion res;
        res.crcVal = crc.finish();
        return res.hash;
    }
    catch (Throwable)
    {
        return super.toHash();
    }
  }

  // helper for checking that the stream is readable
  final protected void assertReadable() {
    if (!readable)
      throw new ReadException("Stream is not readable");
  }
  // helper for checking that the stream is writeable
  final protected void assertWriteable() {
    if (!writeable)
      throw new WriteException("Stream is not writeable");
  }
  // helper for checking that the stream is seekable
  final protected void assertSeekable() {
    if (!seekable)
      throw new SeekException("Stream is not seekable");
  }

  unittest { // unit test for Issue 3363
    import std.stdio;
    immutable fileName = undead.internal.file.deleteme ~ "-issue3363.txt";
    auto w = std.stdio.File(fileName, "w");
    scope (exit) std.file.remove(fileName);
    w.write("one two three");
    w.close();
    auto r = std.stdio.File(fileName, "r");
    const(char)[] constChar;
    string str;
    char[] chars;
    r.readf("%s %s %s", &constChar, &str, &chars);
    assert (constChar == "one", constChar);
    assert (str == "two", str);
    assert (chars == "three", chars);
  }

  unittest { //unit tests for Issue 1668
    void tryFloatRoundtrip(float x, string fmt = "", string pad = "") {
      auto s = new MemoryStream();
      s.writef(fmt, x, pad);
      s.position = 0;

      float f;
      assert(s.readf(&f));
      assert(x == f || (x != x && f != f)); //either equal or both NaN
    }

    tryFloatRoundtrip(1.0);
    tryFloatRoundtrip(1.0, "%f");
    tryFloatRoundtrip(1.0, "", " ");
    tryFloatRoundtrip(1.0, "%f", " ");

    tryFloatRoundtrip(3.14);
    tryFloatRoundtrip(3.14, "%f");
    tryFloatRoundtrip(3.14, "", " ");
    tryFloatRoundtrip(3.14, "%f", " ");

    float nan = float.nan;
    tryFloatRoundtrip(nan);
    tryFloatRoundtrip(nan, "%f");
    tryFloatRoundtrip(nan, "", " ");
    tryFloatRoundtrip(nan, "%f", " ");

    float inf = 1.0/0.0;
    tryFloatRoundtrip(inf);
    tryFloatRoundtrip(inf, "%f");
    tryFloatRoundtrip(inf, "", " ");
    tryFloatRoundtrip(inf, "%f", " ");

    tryFloatRoundtrip(-inf);
    tryFloatRoundtrip(-inf,"%f");
    tryFloatRoundtrip(-inf, "", " ");
    tryFloatRoundtrip(-inf, "%f", " ");
  }
}

/// An exception for File errors.
class StreamFileException: StreamException {
  /// Construct a StreamFileException with given error message.
  this(string msg) { super(msg); }
}

/// An exception for errors during File.open.
class OpenException: StreamFileException {
  /// Construct an OpenFileException with given error message.
  this(string msg) { super(msg); }
}

/// Specifies the $(LREF File) access mode used when opening the file.
enum FileMode {
  In = 1,     /// Opens the file for reading.
  Out = 2,    /// Opens the file for writing.
  OutNew = 6, /// Opens the file for writing, creates a new file if it doesn't exist.
  Append = 10 /// Opens the file for writing, appending new data to the end of the file.
}

version (Windows) {
  private import core.sys.windows.windows;
  extern (Windows) {
    void FlushFileBuffers(HANDLE hFile);
    DWORD  GetFileType(HANDLE hFile);
  }
}
version (Posix) {
  private import core.sys.posix.fcntl;
  private import core.sys.posix.unistd;
  alias HANDLE = int;
}

/// This subclass is for unbuffered file system streams.
class File: Stream {

  version (Windows) {
    private HANDLE hFile;
  }
  else version (Posix) {
    private HANDLE hFile = -1;
  }

  this() {
    super();
    version (Windows) {
      hFile = null;
    }
    version (Posix) {
      hFile = -1;
    }
    isopen = false;
  }

  // opens existing handle; use with care!
  this(HANDLE hFile, FileMode mode) {
    super();
    this.hFile = hFile;
    readable = cast(bool)(mode & FileMode.In);
    writeable = cast(bool)(mode & FileMode.Out);
    version(Windows) {
      seekable = GetFileType(hFile) == 1; // FILE_TYPE_DISK
    } else {
      const result = lseek(hFile, 0, 0);
      seekable = (result != ~0);
    }
  }

  /***
   * Create the stream with no open file, an open file in read mode, or an open
   * file with explicit file mode.
   * mode, if given, is a combination of FileMode.In
   * (indicating a file that can be read) and FileMode.Out (indicating a file
   * that can be written).
   * Opening a file for reading that doesn't exist will error.
   * Opening a file for writing that doesn't exist will create the file.
   * The FileMode.OutNew mode will open the file for writing and reset the
   * length to zero.
   * The FileMode.Append mode will open the file for writing and move the
   * file position to the end of the file.
   */
  this(string filename, FileMode mode = FileMode.In)
  {
      this();
      open(filename, mode);
  }


  /***
   * Open a file for the stream, in an identical manner to the constructors.
   * If an error occurs an OpenException is thrown.
   */
  void open(string filename, FileMode mode = FileMode.In) {
    close();
    int access, share, createMode;
    parseMode(mode, access, share, createMode);
    seekable = true;
    readable = cast(bool)(mode & FileMode.In);
    writeable = cast(bool)(mode & FileMode.Out);
    version (Windows) {
      hFile = CreateFileW(filename.tempCString!wchar(), access, share,
                          null, createMode, 0, null);
      isopen = hFile != INVALID_HANDLE_VALUE;
    }
    version (Posix) {
      hFile = core.sys.posix.fcntl.open(filename.tempCString(), access | createMode, share);
      isopen = hFile != -1;
    }
    if (!isopen)
      throw new OpenException(cast(string) ("Cannot open or create file '"
                                            ~ filename ~ "'"));
    else if ((mode & FileMode.Append) == FileMode.Append)
      seekEnd(0);
  }

  private void parseMode(int mode,
                         out int access,
                         out int share,
                         out int createMode) {
    version (Windows) {
      share |= FILE_SHARE_READ | FILE_SHARE_WRITE;
      if (mode & FileMode.In) {
        access |= GENERIC_READ;
        createMode = OPEN_EXISTING;
      }
      if (mode & FileMode.Out) {
        access |= GENERIC_WRITE;
        createMode = OPEN_ALWAYS; // will create if not present
      }
      if ((mode & FileMode.OutNew) == FileMode.OutNew) {
        createMode = CREATE_ALWAYS; // resets file
      }
    }
    version (Posix) {
      share = octal!666;
      if (mode & FileMode.In) {
        access = O_RDONLY;
      }
      if (mode & FileMode.Out) {
        createMode = O_CREAT; // will create if not present
        access = O_WRONLY;
      }
      if (access == (O_WRONLY | O_RDONLY)) {
        access = O_RDWR;
      }
      if ((mode & FileMode.OutNew) == FileMode.OutNew) {
        access |= O_TRUNC; // resets file
      }
    }
  }

  /// Create a file for writing.
  void create(string filename) {
    create(filename, FileMode.OutNew);
  }

  /// ditto
  void create(string filename, FileMode mode) {
    close();
    open(filename, mode | FileMode.OutNew);
  }

  /// Close the current file if it is open; otherwise it does nothing.
  override void close() {
    if (isopen) {
      super.close();
      if (hFile) {
        version (Windows) {
          CloseHandle(hFile);
          hFile = null;
        } else version (Posix) {
          core.sys.posix.unistd.close(hFile);
          hFile = -1;
        }
      }
    }
  }

  // destructor, closes file if still opened
  ~this() { close(); }

  version (Windows) {
    // returns size of stream
    override @property ulong size() {
      assertSeekable();
      uint sizehi;
      const uint sizelow = GetFileSize(hFile,&sizehi);
      return (cast(ulong)sizehi << 32) + sizelow;
    }
  }

  override size_t readBlock(void* buffer, size_t size) {
    assertReadable();
    version (Windows) {
      auto dwSize = to!DWORD(size);
      ReadFile(hFile, buffer, dwSize, &dwSize, null);
      size = dwSize;
    } else version (Posix) {
      size = core.sys.posix.unistd.read(hFile, buffer, size);
      if (size == -1)
        size = 0;
    }
    readEOF = (size == 0);
    return size;
  }

  override size_t writeBlock(const void* buffer, size_t size) {
    assertWriteable();
    version (Windows) {
      auto dwSize = to!DWORD(size);
      WriteFile(hFile, buffer, dwSize, &dwSize, null);
      size = dwSize;
    } else version (Posix) {
      size = core.sys.posix.unistd.write(hFile, buffer, size);
      if (size == -1)
        size = 0;
    }
    return size;
  }

  override ulong seek(long offset, SeekPos rel) {
    assertSeekable();
    version (Windows) {
      int hi = cast(int)(offset>>32);
      uint low = SetFilePointer(hFile, cast(int)offset, &hi, rel);
      if ((low == INVALID_SET_FILE_POINTER) && (GetLastError() != 0))
        throw new SeekException("unable to move file pointer");
      ulong result = (cast(ulong)hi << 32) + low;
    } else version (Posix) {
      auto result = lseek(hFile, cast(off_t)offset, rel);
      if (result == cast(typeof(result))-1)
        throw new SeekException("unable to move file pointer");
    }
    readEOF = false;
    return cast(ulong)result;
  }

  /***
   * For a seekable file returns the difference of the size and position and
   * otherwise returns 0.
   */

  override @property size_t available() {
    if (seekable) {
      ulong lavail = size - position;
      if (lavail > size_t.max) lavail = size_t.max;
      return cast(size_t)lavail;
    }
    return 0;
  }

  // OS-specific property, just in case somebody wants
  // to mess with underlying API
  HANDLE handle() { return hFile; }

}


