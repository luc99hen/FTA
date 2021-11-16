## shopt

### extglob

Globbing refers to pattern matching. Bash uses simple globbing like, echo l* which expand to list of files in current directory that start with letter l. Of course , as you can guess, it's simple and limited.

`extglob` stands for extended globbing. This option allows for more advanced pattern matching. From man bash:

> extglob If set, the extended pattern matching features described above under Pathname Expansion are enabled.

If the extglob shell option is enabled using the shopt builtin, several
extended pattern matching operators are recognized.  In  the  following
description, a pattern-list is a list of one or more patterns separated
by a |.  Composite patterns may be formed using  one  or  more  of  the
following sub-patterns:

      ?(pattern-list)
             Matches zero or one occurrence of the given patterns
      *(pattern-list)
             Matches zero or more occurrences of the given patterns
      +(pattern-list)
             Matches one or more occurrences of the given patterns
      @(pattern-list)
             Matches one of the given patterns
      !(pattern-list)
             Matches anything except one of the given patterns

## [BASH_REMATCH](https://blog.csdn.net/dc666/article/details/46007507)
双目运算符 =~；它和 == 以及!= 具有同样的优先级。如果使用了它，则其右边的字符串就被认为是一个扩展的正则表达式来匹配。如果字符串和模式匹配，则返回值是 0，否则返回 1。如果这个正则表达式有语法错误，则整个条件表达式的返回值是 2。


## tr

`tr [OPTIONS]... SET1 [SET2]`

### options
- `-d`: delete characters in SET1
- `-s`: replace each input sequence of a repeated character that is listed in SET1 with a single occurrence of that character

### SETES identifiers
- [:blank:]       all horizontal whitespace
- [:punct:]       all punctuation characters
- [:space:]       all horizontal or vertical whitespace


### examples

```
echo {{text}} | tr {{find_character}} {{replace_character}}
```