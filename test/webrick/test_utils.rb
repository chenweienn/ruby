require "test/unit"
require "webrick/utils"

class TestWEBrickUtils < Test::Unit::TestCase
  def assert_expired(flag, m)
    if m == WEBrick::Utils
      handler = WEBrick::Utils::TimeoutHandler.instance
      assert_equal(flag, handler.instance_eval{ @timeout_info.empty? })
    end
  end

  EX = Class.new(StandardError)

  def test_no_timeout
    m = WEBrick::Utils
    assert_equal(:foo, m.timeout(10){ :foo })
    assert_expired(true, m)
  end

  def test_nested_timeout_outer
    m = WEBrick::Utils
    i = 0
    assert_raise(Timeout::Error){
      m.timeout(2){
        assert_raise(Timeout::Error){ m.timeout(1){ i += 1; sleep } }
        assert_expired(false, m)
        i += 1
        sleep
      }
    }
    assert_equal(2, i)
    assert_expired(true, m)
  end

  def test_timeout_default_execption
    m = WEBrick::Utils
    assert_raise(Timeout::Error){ m.timeout(0.1){ sleep } }
    assert_expired(true, m)
  end

  def test_timeout_custom_exception
    m = WEBrick::Utils
    ex = EX
    assert_raise(ex){ m.timeout(0.1, ex){ sleep } }
    assert_expired(true, m)
  end

  def test_nested_timeout_inner_custom_exception
    m = WEBrick::Utils
    ex = EX
    i = 0
    assert_raise(ex){
      m.timeout(10){
        m.timeout(1, ex){ i += 1; sleep }
      }
      sleep
    }
    assert_equal(1, i)
    assert_expired(true, m)
  end

  def test_nested_timeout_outer_custom_exception
    m = WEBrick::Utils
    ex = EX
    i = 0
    assert_raise(Timeout::Error){
      m.timeout(1){
        m.timeout(10, ex){ i += 1; sleep }
      }
      sleep
    }
    assert_equal(1, i)
    assert_expired(true, m)
  end

  def test_create_listeners
    addr = listener_address(0)
    port = addr.slice!(1)
    assert_kind_of(Integer, port, "dynamically chosen port number")
    assert_equal(["AF_INET", "127.0.0.1", "127.0.0.1"], addr)

    assert_equal(["AF_INET", port, "127.0.0.1", "127.0.0.1"],
                 listener_address(port),
                 "specific port number")

    assert_equal(["AF_INET", port, "127.0.0.1", "127.0.0.1"],
                 listener_address(port.to_s),
                 "specific port number string")
  end

  def listener_address(port)
    listeners = WEBrick::Utils.create_listeners("127.0.0.1", port)
    srv = listeners.first
    assert_kind_of TCPServer, srv
    srv.addr
  ensure
    listeners.each(&:close) if listeners
  end
end
