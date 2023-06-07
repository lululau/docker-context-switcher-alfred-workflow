require_relative 'alfred'

ICON = {
  'true' => 'on.png',
  'false' => 'off.png'
}

class DockerContext
  attr_accessor :name, :endpoint, :current

  def initialize(raw_context_info)
    @name, @endpoint, @current = raw_context_info.split("\t")
  end

  def sort_key
    current = @current == 'true' ? 'a' : 'b'
    name = @name == 'default' ? "a#{@name}" : "b#{@name}"
    [current, name]
  end

  class << self
    def all
      `docker context ls --format "{{.Name}}\t{{.DockerEndpoint}}\t{{.Current}}"`.split("\n").map do |raw_context_info|
        DockerContext.new(raw_context_info)
      end
    end
  end
end

def list(query=nil)
  contextes = DockerContext.all
    .select { |ctx| query.nil? || ctx.name.include?(query) }
    .sort_by(&:sort_key)
  item_list = ItemList.new
  item_list.items = contextes.map { |ctx|
    item = Item.new
    item.title = ctx.name
    item.subtitle = "ctx.endpoint"
    item.icon[:text] = ICON[ctx.current]
    item.attributes = {
      arg: ctx.name
    }
    item
  }
  item_list.to_xml
end


if ARGV[0] == 'list'
  print list(ARGV[1])
elsif ARGV[0]
  context_name = ARGV[0]
  system "docker context use #{context_name}"
end
