fn greeting(name: &str) -> String {
    format!("hello, {name}")
}

fn main() {
    println!("{}", greeting("world"));
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn greets() {
        insta::assert_snapshot!(greeting("world"), @"hello, world");
    }
}
