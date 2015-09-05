require 'parslet'

# This module is meant to override the default parser's error raising in order
# to only get the deepest, right-most cause.
module ErrorHandler
  def deepest_leaves(leaves)
    _, max_depth = leaves.max_by { |leaf| leaf[1] }

    leaves.select { |leaf| leaf[1] == max_depth }
  end

  def deepest(cause, depth = 0)
    children = cause.children.reject { |child| too_deep? child }

    if children.empty?
      [cause, depth + 1]
    else
      leaves = children.map { |child| deepest child, depth + 1 }

      deepest_leaves(leaves).max_by { |leaf| leaf[0].pos }
    end
  end

  def parse(*args)
    super(*args)
  rescue Parslet::ParseFailed => error
    deepest(error.cause)[0].raise
  end
end
