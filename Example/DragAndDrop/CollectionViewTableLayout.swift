//
//  CollectionViewTableLayout.swift
//  DragAndDrop
//
//  Created by Mat Cegiela on 5/28/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit

protocol CollectionViewTableLayoutDelegate {
    func collectionView(_ collectionView:UICollectionView, sizeOfItemAt indexPath:IndexPath) -> CGSize
    func collectionView(_ collectionView:UICollectionView, tableLayoutPositionFor indexPath:IndexPath) -> TableLayoutPosition
}

struct TableLayoutPosition: Equatable {
    //Zero in either direction is interpreted as off the table
    //Top left corner of rable is 1,1
    var x: Int = 0
    var y: Int = 0
}

func ==(lhs: TableLayoutPosition, rhs: TableLayoutPosition) -> Bool {
    return lhs.x == rhs.x && lhs.y == rhs.y
}

class CollectionViewTableLayout: UICollectionViewLayout {
    private var layoutAttributesByIndexPath = [IndexPath : UICollectionViewLayoutAttributes]()
    private var layoutPositionByIndexPath = [IndexPath : TableLayoutPosition]()
    private var tableLayoutBounds = TableLayoutPosition()
    private var columnWidths = [CGFloat]()
    private var rowHeights = [CGFloat]()
    
    private var totalLayoutSize = CGSize()
    
    //Setting this should improve performance.
    //All items will be assumed to have this size if it's set.
    var uniformItemSize: CGSize?// = CGSize(width: 0.0, height: 0.0)
    
    var maximizeItemSize = false
    var layoutDelegate: CollectionViewTableLayoutDelegate?
    
    override var collectionViewContentSize: CGSize {
        return totalLayoutSize
    }
    
    override func invalidateLayout() {
        layoutAttributesByIndexPath.removeAll()
        totalLayoutSize = CGSize()
        super.invalidateLayout()
    }
    
    override func prepare() {
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
                let layoutPosition = delegate.collectionView(collectionView, tableLayoutPositionFor: layoutItem.indexPath)
                    //delegate.layoutPositionForItem(at: layoutItem.indexPath, for: collectionView)
                layoutPositionByIndexPath[layoutItem.indexPath] = layoutPosition
                tableLayoutBounds.x = max(tableLayoutBounds.x, layoutPosition.x)
                tableLayoutBounds.y = max(tableLayoutBounds.y, layoutPosition.y)
                
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
                    
                    let itemPosition = layoutPositionByIndexPath[layoutItem.indexPath] ?? TableLayoutPosition()
                    let columnWidth = max(widthsByPosition[itemPosition.x] ?? 0.0, layoutItem.size.width)
                    widthsByPosition[itemPosition.x] = columnWidth
                    let rowHeight = max(heightsByPosition[itemPosition.y] ?? 0.0, layoutItem.size.height)
                    heightsByPosition[itemPosition.y] = rowHeight
                }
            }
            
            //Fill in any blanks in column widths
            columnWidths.removeAll()
            for i in 0..<tableLayoutBounds.x {
                let width = widthsByPosition[i] ?? 0.0
                columnWidths.append(width)
            }
            
            //Fill in any blanks in row heights
            rowHeights.removeAll()
            for i in 0..<tableLayoutBounds.y {
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
                var centerX = layoutItem.size.width / 2
                var centerY = layoutItem.size.height / 2
                
                let widths = columnWidths[0...position.x]
                centerX = widths.reduce(0, +) - widths[position.x]
                let heights = rowHeights[0...position.y]
                centerY = heights.reduce(0, +) - heights[position.y]
                
                layoutItem.center = CGPoint(x: centerX, y: centerY)
            }
        }
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return layoutAttributesByIndexPath[indexPath]
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return Array(layoutAttributesByIndexPath.values).filter { (item) -> Bool in
            return item.frame.intersects(rect)
        }
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        //If returning true a full recalculation will be triggered repeatedly during scrolling
        return false
    }
    
    override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds)
        return context
    }
}
