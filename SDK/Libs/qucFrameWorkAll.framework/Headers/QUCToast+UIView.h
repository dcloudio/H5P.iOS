/***************************************************************************
 
Toast+UIView.h
Toast
Version 2.0

Copyright (c) 2013 Charles Scalesse.
 
Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:
 
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
***************************************************************************/


#import <Foundation/Foundation.h>

@interface UIView (QUCToast)

// each makeToast method creates a view and displays it as toast
- (void)makeToast:(NSString *)message duration:(CGFloat)interval position:(id)position keyboardheight:(NSInteger) keyboardheight;
- (void)makeToast:(NSString *)message duration:(CGFloat)interval position:(id)position;


// the showToast methods display any view as toast
- (void)showToast:(UIView *)toast duration:(CGFloat)interval position:(id)point keyboardheight:(NSInteger) keyboardheight;

// hxs - add - richMessage
- (void)makeToastWithHeadMessage:(NSString *)headMessage linkMessage:(NSString *)linkMessage tailMessage:(NSString *)tailMessage duration:(CGFloat)duration position:(id)position target:(id)target;

@end
