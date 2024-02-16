// Based on https://github.com/dangreco/edgy
// MIT License
//
// Copyright (c) 2019 Daniel Greco
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.


use image::{GenericImageView, ImageBuffer, Luma};

pub fn process_image(source_filename: &str, output_filename: &str, blur_modifier: i32) {
    tracing::debug!({%source_filename, %output_filename, %blur_modifier}, "Starting image processing");
    let source = image::open(source_filename).unwrap();
    let (width, height) = source.dimensions();
    let sigma = (((width * height) as f32) / 3630000.0) * blur_modifier as f32;
    let gaussed = source.blur(sigma);
    let gray = gaussed.to_luma();

    let sobel_width:u32 = gray.width()-2;
    let sobel_height:u32 = gray.height()-2;
    let mut buff:ImageBuffer<Luma<u8>, Vec<u8>> = ImageBuffer::new(sobel_width, sobel_height);

    for i in 0..sobel_width {
        for j in 0..sobel_height {
            let val0 = gray.get_pixel(i, j).data[0] as i32;
            let val1 = gray.get_pixel(i+1, j).data[0] as i32;
            let val2 = gray.get_pixel(i+2, j).data[0] as i32;
            let val3 = gray.get_pixel(i, j+1).data[0] as i32;
            let val5 = gray.get_pixel(i+2, j+1).data[0] as i32;
            let val6 = gray.get_pixel(i, j+2).data[0] as i32;
            let val7 = gray.get_pixel(i+1, j+2).data[0] as i32;
            let val8 = gray.get_pixel(i+2, j+2).data[0] as i32;

            let gx = (-1*val0) + (-2*val3) + (-1*val6) + val2 + (2*val5) + val8;
            let gy = (-1*val0) + (-2*val1) + (-1*val2) + val6 + (2*val7) + val8;

            let mut mag = ((gx as f64).powi(2) + (gy as f64).powi(2)).sqrt();

            if mag > 255.0 {
                mag = 255.0;
            }

            buff.put_pixel(i, j, Luma([mag as u8]));
        }
    }


    buff.save(output_filename).unwrap();
}
