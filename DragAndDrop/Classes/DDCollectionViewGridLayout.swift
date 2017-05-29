//
//  DDCollectionViewGridLayout.swift
//  Pods
//
//  Created by Mat Cegiela on 5/28/17.
//
//

import UIKit

public protocol DDCollectionViewGridLayoutDelegate {
    func collectionView(_ collectionView:UICollectionView, sizeOfItemAt indexPath:IndexPath) -> CGSize
    func collectionView(_ collectionView:UICollectionView, gridLayoutPositionFor indexPath:IndexPath) -> GridLayoutPosition
}

public struct GridLayoutPosition: Equatable {
    //Zero in either direction is interpreted as 'off the grid' and item is not shown
    //Top left corner is 1,1
    var x: Int = 0
    var y: Int = 0
    
    public init(x: Int = 0, y: Int = 0) {
        self.x = x
        self.y = y
    }
}

public func ==(lhs: GridLayoutPosition, rhs: GridLayoutPosition) -> Bool {
    return lhs.x == rhs.x && lhs.y == rhs.y
}

public class DDCollectionViewGridLayout: UICollectionViewLayout {
    private var layoutAttributesByIndexPath = [IndexPath : UICollectionViewLayoutAttributes]()
    private var layoutPositionByIndexPath = [IndexPath : GridLayoutPosition]()
    private var gridLayoutBounds = GridLayoutPosition()
    private var columnWidths = [CGFloat]()
    private var rowHeights = [CGFloat]()
    
    private var totalLayoutSize = CGSize()
    
    //Setting this should improve performance.
    //All items will be assumed to have this size if it's set.
    var uniformItemSize: CGSize?// = CGSize(width: 0.0, height: 0.0)
    
//    public var maximizeItemSize = false
    public var layoutDelegate: DDCollectionViewGridLayoutDelegate?
    
    override public var collectionViewContentSize: CGSize {
        return totalLayoutSize
    }
    
    override public func invalidateLayout() {
        layoutAttributesByIndexPath.removeAll()
        totalLayoutSize = CGSize()
        super.invalidateLayout()
    }
    
    override public func prepare() {
        calculateLayout()
        super.prepare()
    }
    
    private func calculateLayout() {
        if layoutAttributesByIndexPath.count == 0 {
            buildLayoutAttributes()
        }
        calculateColumnAndRowSizes()
        calculateTotalSize()
        calculateItemLayout()
    }
    
    private func buildLayoutAttributes() {
        if let collectionView = collectionView {
            
            //Create a layout attributes instance for each item in collection view
            layoutAttributesByIndexPath.removeAll()
            for section in 0..<collectionView.numberOfSections {
                for item in 0..<collectionView.numberOfItems(inSection: section) {
                    let indexPath = IndexPath(item: item, section: section)
                    let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                    layoutAttributesByIndexPath[indexPath] = attributes
                }
            }
        }
    }
    
    private func calculateColumnAndRowSizes() {
        if let collectionView = collectionView, let delegate = layoutDelegate {
            
            var widthsByPosition = [Int : CGFloat]()
            var heightsByPosition = [Int : CGFloat]()
            
            //Get item positions and sizes
            for layoutItem in layoutAttributesByIndexPath.values {
                let layoutPosition = delegate.collectionView(collectionView, gridLayoutPositionFor: layoutItem.indexPath)
                //delegate.layoutPositionForItem(at: layoutItem.indexPath, for: collectionView)
                layoutPositionByIndexPath[layoutItem.indexPath] = layoutPosition
                gridLayoutBounds.x = max(gridLayoutBounds.x, layoutPosition.x)
                gridLayoutBounds.y = max(gridLayoutBounds.y, layoutPosition.y)
                
                //TODO://////Check if position zero -- mark hidden
                if layoutPosition.x <= 0 || layoutPosition.y <= 0 {
                    layoutItem.isHidden = true
                } else {
                    layoutItem.isHidden = false
                }
                
                //Calculate the size for each column and row, based on item sizes
                if uniformItemSize != nil {
                    layoutItem.size = uniformItemSize!
                } else {
                    //Set column and row sizes to accomodate the biggest items
                    layoutItem.size = delegate.collectionView(collectionView, sizeOfItemAt: layoutItem.indexPath)
                    //delegate.sizeOfItem(at: layoutItem.indexPath, for: collectionView)
                    
                    let itemPosition = layoutPositionByIndexPath[layoutItem.indexPath] ?? GridLayoutPosition()
                    let columnWidth = max(widthsByPosition[itemPosition.x] ?? 0.0, layoutItem.size.width)
                    widthsByPosition[itemPosition.x] = columnWidth
                    let rowHeight = max(heightsByPosition[itemPosition.y] ?? 0.0, layoutItem.size.height)
                    heightsByPosition[itemPosition.y] = rowHeight
                }
            }
            
            //Fill in any blanks in column widths
            columnWidths.removeAll()
            for i in 0..<gridLayoutBounds.x {
                let width = widthsByPosition[i] ?? 0.0
                columnWidths.append(width)
            }
            
            //Fill in any blanks in row heights
            rowHeights.removeAll()
            for i in 0..<gridLayoutBounds.y {
                let height = heightsByPosition[i] ?? 0.0
                rowHeights.append(height)
            }
        }
    }
    
    private func calculateTotalSize() {
        //Calculate total layout size
        let totalWidth = columnWidths.reduce(0.0, +)
        //{ (total, value) -> CGFloat in
        //    total + value
        //}
        let totalHeight = rowHeights.reduce(0.0, +)
        
        totalLayoutSize = CGSize(width: totalWidth, height: totalHeight)
    }
    
    private func calculateItemLayout() {
        //Calculate item positions
        for layoutItem in layoutAttributesByIndexPath.values {
            
            //Place item in center of it's row and column
            if let position = layoutPositionByIndexPath[layoutItem.indexPath] {
                
                if position.x > 0 && position.y > 0 {
                    var centerX = layoutItem.size.width / 2
                    var centerY = layoutItem.size.height / 2
                    
                    let widths = columnWidths[0..<position.x]
                    centerX = widths.reduce(0, +) - widths[position.x - 1]
                    let heights = rowHeights[0..<position.y]
                    centerY = heights.reduce(0, +) - heights[position.y - 1]
                    
                    layoutItem.center = CGPoint(x: centerX, y: centerY)
                }
            }
        }
    }
    
    override public func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return layoutAttributesByIndexPath[indexPath]
    }
    
    override public func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return Array(layoutAttributesByIndexPath.values).filter { (item) -> Bool in
            return item.frame.intersects(rect)
        }
    }
    
    override public func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        //If returning true a full recalculation will be triggered repeatedly during scrolling
        return false
    }
    
    override public func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds)
        return context
    }
}
